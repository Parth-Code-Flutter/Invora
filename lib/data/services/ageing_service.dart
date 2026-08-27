import 'dart:convert';

import 'package:share_plus/share_plus.dart';

import '../../app/constants/app_storage_key_const.dart';
import '../../app/localization/app_localization.dart';
import '../../app/utils/currency_utils.dart';
import '../models/ageing_model.dart';
import '../models/invoice_model.dart';
import '../models/purchase_models.dart';
import '../repositories/business_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/purchase_repository.dart';
import 'app_storage.dart';

class AgeingService {
  const AgeingService(
    this._business,
    this._invoices,
    this._customers,
    this._purchases,
    this._storage, {
    this.shareImpl = _defaultShare,
  });

  final BusinessRepository _business;
  final InvoiceRepository _invoices;
  final CustomerRepository _customers;
  final PurchaseRepository _purchases;
  final AppStorage _storage;
  final Future<ShareResult> Function(ShareParams params) shareImpl;

  static Future<ShareResult> _defaultShare(ShareParams params) =>
      SharePlus.instance.share(params);

  Future<AgeingPack> build({DateTime? asOf}) async {
    final now = AgeingMath.dateOnly(asOf ?? DateTime.now());
    final profile = await _business.getProfile();
    final statuses = _readStatuses();
    final invoices = await _invoices.listOpenReceivables();
    final bills = await _purchases.listOpenPayables();
    final receivables = <AgeingRow>[];
    for (final invoice in invoices) {
      receivables.add(await _receivableRow(invoice, now, statuses));
    }
    final payables = <AgeingRow>[];
    for (final bill in bills) {
      payables.add(await _payableRow(bill, now, statuses));
    }
    return AgeingPack(
      asOf: now,
      businessName: profile?.businessName.trim().isNotEmpty == true
          ? profile!.businessName.trim()
          : 'Creovo Billing',
      currencySymbol: profile?.currencySymbol ?? '₹',
      upiId: profile?.upiId?.trim().isNotEmpty == true
          ? profile!.upiId!.trim()
          : null,
      receivables: receivables,
      payables: payables,
    );
  }

  String composeDocument(
    AgeingRow row,
    AgeingPack pack, {
    AppLanguage language = AppLanguage.english,
  }) {
    final amount = CurrencyUtils.formatMinor(
      row.balanceMinor,
      symbol: pack.currencySymbol,
    );
    final due = AgeingMath.dateLabel(row.dueDate);
    final overdue = row.daysPastDue > 0;
    return _documentTemplate(
      language: language,
      receivable: row.side == AgeingSide.receivables,
      partyName: row.partyName,
      documentNumber: row.documentNumber,
      amount: amount,
      due: due,
      overdue: overdue,
      daysPastDue: row.daysPastDue.abs(),
      businessName: pack.businessName,
      upiId: pack.upiId,
    );
  }

  String composeBucket(
    List<AgeingRow> rows,
    AgeingPack pack, {
    AppLanguage language = AppLanguage.english,
  }) {
    if (rows.isEmpty) return '';
    final receivable = rows.first.side == AgeingSide.receivables;
    final total = CurrencyUtils.formatMinor(
      rows.fold(0, (sum, row) => sum + row.balanceMinor),
      symbol: pack.currencySymbol,
    );
    final lines = [
      for (final row in rows)
        '${row.documentNumber}  ·  ${row.partyName}  ·  ${CurrencyUtils.formatMinor(row.balanceMinor, symbol: pack.currencySymbol)}  ·  ${_duePhrase(language, row)}',
    ];
    return _bucketTemplate(
      language: language,
      receivable: receivable,
      total: total,
      count: rows.length,
      lines: lines,
      businessName: pack.businessName,
    );
  }

  Future<AgeingReminderStatus> shareDocument(
    AgeingRow row,
    AgeingPack pack, {
    AppLanguage language = AppLanguage.english,
  }) async {
    final text = composeDocument(row, pack, language: language);
    await _writeStatus(row.storageKey, AgeingReminderStatus.prepared);
    return _share(text, row.storageKey);
  }

  Future<AgeingReminderStatus> shareBucket(
    List<AgeingRow> rows,
    AgeingPack pack, {
    AppLanguage language = AppLanguage.english,
  }) async {
    if (rows.isEmpty) return AgeingReminderStatus.none;
    final text = composeBucket(rows, pack, language: language);
    for (final row in rows) {
      await _writeStatus(row.storageKey, AgeingReminderStatus.prepared);
    }
    final status = await _share(text, rows.first.storageKey, persist: false);
    for (final row in rows) {
      await _writeStatus(row.storageKey, status);
    }
    return status;
  }

  static AgeingReminderStatus statusFromShare(ShareResultStatus result) {
    return switch (result) {
      ShareResultStatus.success => AgeingReminderStatus.shared,
      ShareResultStatus.dismissed => AgeingReminderStatus.skipped,
      ShareResultStatus.unavailable => AgeingReminderStatus.prepared,
    };
  }

  Future<AgeingRow> _receivableRow(
    InvoiceSummaryModel invoice,
    DateTime asOf,
    Map<String, AgeingReminderStatus> statuses,
  ) async {
    final due = AgeingMath.dateOnly(invoice.dueDate ?? invoice.invoiceDate);
    final days = AgeingMath.daysPastDue(due, asOf);
    String? mobile;
    if (invoice.customerId != null) {
      mobile = (await _customers.getById(invoice.customerId!))?.mobile;
    }
    final row = AgeingRow(
      side: AgeingSide.receivables,
      documentId: invoice.id,
      partyId: invoice.customerId,
      documentNumber: invoice.invoiceNumber,
      partyName: invoice.customerName,
      partyMobile: mobile,
      dueDate: due,
      daysPastDue: days,
      bucket: AgeingMath.bucketFor(days),
      balanceMinor: invoice.balanceMinor,
    );
    return row.withStatus(
      statuses[row.storageKey] ?? AgeingReminderStatus.none,
    );
  }

  Future<AgeingRow> _payableRow(
    PurchaseBillSummary bill,
    DateTime asOf,
    Map<String, AgeingReminderStatus> statuses,
  ) async {
    final due = AgeingMath.dateOnly(bill.dueDate ?? bill.billDate);
    final days = AgeingMath.daysPastDue(due, asOf);
    final supplier = await _purchases.getSupplier(bill.supplierId);
    final row = AgeingRow(
      side: AgeingSide.payables,
      documentId: bill.id,
      partyId: bill.supplierId,
      documentNumber: bill.billNumber,
      partyName: bill.supplierName,
      partyMobile: supplier?.mobile,
      dueDate: due,
      daysPastDue: days,
      bucket: AgeingMath.bucketFor(days),
      balanceMinor: bill.balanceMinor,
    );
    return row.withStatus(
      statuses[row.storageKey] ?? AgeingReminderStatus.none,
    );
  }

  Future<AgeingReminderStatus> _share(
    String text,
    String key, {
    bool persist = true,
  }) async {
    final result = await shareImpl(
      ShareParams(text: text, subject: 'Payment reminder'),
    );
    final status = statusFromShare(result.status);
    if (persist) await _writeStatus(key, status);
    return status;
  }

  Map<String, AgeingReminderStatus> _readStatuses() {
    final raw = _storage.getString(AppStorageKeyConst.ageingReminderEvents);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final entry in decoded.entries)
          entry.key: AgeingReminderStatus.values.firstWhere(
            (value) => value.name == entry.value,
            orElse: () => AgeingReminderStatus.none,
          ),
      }..removeWhere(
        (key, value) =>
            value == AgeingReminderStatus.none || value.name == 'delivered',
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeStatus(String key, AgeingReminderStatus status) async {
    if (status.label.toLowerCase() == 'delivered') return;
    final current = _readStatuses();
    current[key] = status;
    await _storage.setString(
      AppStorageKeyConst.ageingReminderEvents,
      jsonEncode({
        for (final entry in current.entries)
          if (entry.value != AgeingReminderStatus.none)
            entry.key: entry.value.name,
      }),
    );
  }

  String _duePhrase(AppLanguage language, AgeingRow row) {
    if (row.daysPastDue <= 0) {
      return switch (language) {
        AppLanguage.hindi => 'देय ${AgeingMath.dateLabel(row.dueDate)}',
        AppLanguage.gujarati => 'બાકી ${AgeingMath.dateLabel(row.dueDate)}',
        AppLanguage.english => 'due ${AgeingMath.dateLabel(row.dueDate)}',
      };
    }
    return switch (language) {
      AppLanguage.hindi => '${row.daysPastDue} दिन अतिदेय',
      AppLanguage.gujarati => '${row.daysPastDue} દિવસ મુદત વીતી',
      AppLanguage.english => '${row.daysPastDue} days overdue',
    };
  }

  String _documentTemplate({
    required AppLanguage language,
    required bool receivable,
    required String partyName,
    required String documentNumber,
    required String amount,
    required String due,
    required bool overdue,
    required int daysPastDue,
    required String businessName,
    required String? upiId,
  }) {
    final dueLine = overdue
        ? switch (language) {
            AppLanguage.english =>
              'was due on $due ($daysPastDue days overdue)',
            AppLanguage.hindi =>
              'की देय तिथि $due थी ($daysPastDue दिन अतिदेय)',
            AppLanguage.gujarati =>
              'ની તારીખ $due હતી ($daysPastDue દિવસ મુદત વીતી)',
          }
        : switch (language) {
            AppLanguage.english => 'is due on $due (not yet due)',
            AppLanguage.hindi => 'की देय तिथि $due है (अभी अतिदेय नहीं)',
            AppLanguage.gujarati => 'ની તારીખ $due છે (હજુ મુદત બાકી)',
          };
    final upi = upiId == null || upiId.isEmpty ? '' : '\nUPI: $upiId';
    final prepared = switch (language) {
      AppLanguage.english =>
        'This reminder was prepared in Creovo Billing. Receipt has not been confirmed.',
      AppLanguage.hindi =>
        'यह अनुस्मारक Creovo Billing में तैयार किया गया है। इसे डिलीवर नहीं माना गया है।',
      AppLanguage.gujarati =>
        'આ યાદ અપાવવું Creovo Billingમાં તૈયાર કર્યું છે. તેને ડિલિવર ગણ્યું નથી.',
    };
    if (receivable) {
      return switch (language) {
        AppLanguage.english =>
          'Payment reminder\nStatus: Prepared\n\nHello $partyName,\n\nInvoice $documentNumber for $amount $dueLine.\nPlease pay the outstanding amount at your earliest convenience.\n\n$businessName$upi\n\n$prepared',
        AppLanguage.hindi =>
          'भुगतान अनुस्मारक\nस्थिति: Prepared\n\nनमस्ते $partyName,\n\nचालान $documentNumber $amount $dueLine।\nकृपया बकाया राशि जल्द से जल्द चुकाएँ।\n\n$businessName$upi\n\n$prepared',
        AppLanguage.gujarati =>
          'ચુકવણી યાદ\nસ્થિતિ: Prepared\n\nનમસ્તે $partyName,\n\nઇન્વૉઇસ $documentNumber $amount $dueLine.\nકૃપા કરી બાકી રકમ જલ્દી ચૂકવો.\n\n$businessName$upi\n\n$prepared',
      };
    }
    return switch (language) {
      AppLanguage.english =>
        'Payment reminder\n\nSupplier bill $documentNumber for $partyName is $amount and $dueLine.\nThis is an internal follow-up to pay. It does not change the legal due date.\n\n$businessName\n\n$prepared',
      AppLanguage.hindi =>
        'भुगतान अनुस्मारक\n\nआपूर्तिकर्ता बिल $documentNumber ($partyName) $amount है और $dueLine।\nयह भुगतान के लिए आंतरिक अनुस्मारक है। कानूनी देय तिथि नहीं बदलती।\n\n$businessName\n\n$prepared',
      AppLanguage.gujarati =>
        'ચુકવણી યાદ\n\nસપ્લાયર બિલ $documentNumber ($partyName) $amount છે અને $dueLine.\nઆ ચૂકવવા માટે આંતરિક યાદ છે. કાનૂની તારીખ બદલાતી નથી.\n\n$businessName\n\n$prepared',
    };
  }

  String _bucketTemplate({
    required AppLanguage language,
    required bool receivable,
    required String total,
    required int count,
    required List<String> lines,
    required String businessName,
  }) {
    final prepared = switch (language) {
      AppLanguage.english =>
        'This list was prepared in Creovo Billing. Receipt has not been confirmed.',
      AppLanguage.hindi =>
        'यह सूची Creovo Billing में तैयार की गई है। इसे डिलीवर नहीं माना गया है।',
      AppLanguage.gujarati =>
        'આ યાદી Creovo Billingમાં તૈયાર કરી છે. તેને ડિલિવર ગણી નથી.',
    };
    final header = switch (language) {
      AppLanguage.english =>
        receivable
            ? 'Payment reminders · $count invoices · $total\nStatus: Prepared'
            : 'Bills to pay · $count bills · $total\nStatus: Prepared',
      AppLanguage.hindi =>
        receivable
            ? 'भुगतान अनुस्मारक · $count चालान · $total\nस्थिति: Prepared'
            : 'चुकाने के बिल · $count बिल · $total\nस्थिति: Prepared',
      AppLanguage.gujarati =>
        receivable
            ? 'ચુકવણી યાદ · $count ઇન્વૉઇસ · $total\nસ્થિતિ: Prepared'
            : 'ચૂકવવાના બિલ · $count બિલ · $total\nસ્થિતિ: Prepared',
    };
    return '$header\n\n${lines.map((line) => '• $line').join('\n')}\n\n$businessName\n\n$prepared';
  }
}
