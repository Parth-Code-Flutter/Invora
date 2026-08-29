import 'dart:convert';

import 'package:drift/drift.dart';

import '../../app/enums/invoice_status.dart';
import '../../app/enums/item_type.dart';
import '../../app/enums/tax_type.dart';
import '../../app/utils/quantity_utils.dart';
import '../models/customer_model.dart';
import '../models/data_import_models.dart';
import '../models/invoice_calculation_models.dart';
import '../models/invoice_model.dart';
import '../models/product_service_model.dart';
import '../models/purchase_models.dart';
import '../models/stock_models.dart';
import '../repositories/customer_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/purchase_repository.dart';
import 'app_database.dart';
import 'csv_codec.dart';
import 'data_export_service.dart';
import 'data_import_templates.dart';
import 'import_value_parsers.dart';
import 'invoice_calculation_service.dart';
import 'stock_ledger.dart';
import 'xlsx_sheet_reader.dart';

class DataImportService {
  DataImportService({
    required AppDatabase database,
    required CustomerRepository customers,
    required ProductRepository products,
    required InvoiceRepository invoices,
    required PurchaseRepository purchases,
    InvoiceCalculationService calculation = const InvoiceCalculationService(),
  }) : _database = database,
       _customers = customers,
       _products = products,
       _invoices = invoices,
       _purchases = purchases,
       _calculation = calculation;

  final AppDatabase _database;
  final CustomerRepository _customers;
  final ProductRepository _products;
  final InvoiceRepository _invoices;
  final PurchaseRepository _purchases;
  final InvoiceCalculationService _calculation;

  ImportTemplate templateFor(DataImportKind kind) =>
      DataImportTemplates.of(kind);

  ExportArtifact templateArtifact(DataImportKind kind) {
    final template = DataImportTemplates.of(kind);
    final rows = <List<Object?>>[template.headers, ...template.sample];
    return ExportArtifact(
      fileName: template.fileName,
      bytes: Uint8List.fromList(utf8.encode('\ufeff${CsvCodec.encode(rows)}')),
      extension: 'csv',
    );
  }

  ExportArtifact errorArtifact(ImportBatchResult result) {
    final rows = <List<Object?>>[
      const ['Row', 'Severity', 'Message'],
      ...result.errors.map(
        (issue) => [
          issue.rowNumber,
          issue.warning ? 'warning' : 'error',
          issue.message,
        ],
      ),
    ];
    return ExportArtifact(
      fileName: 'creovo_import_errors.csv',
      bytes: Uint8List.fromList(utf8.encode('\ufeff${CsvCodec.encode(rows)}')),
      extension: 'csv',
    );
  }

  List<List<String>> parseSpreadsheet({
    required Uint8List bytes,
    required String fileName,
  }) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.xlsx')) {
      final grid = XlsxSheetReader.tryParse(bytes);
      if (grid == null || grid.isEmpty) {
        throw const FormatException(
          'This Excel file could not be read. Save the first sheet as CSV and try again.',
        );
      }
      return grid;
    }
    return CsvCodec.decode(utf8.decode(bytes));
  }

  Map<String, String> autoMap(ImportTemplate template, List<String> headers) {
    final mapping = <String, String>{};
    final lookup = <String, String>{};
    for (final header in headers) {
      lookup[ImportValueParsers.normalizeHeader(header)] = header;
    }
    for (final column in template.columns) {
      final keys = [
        column.header,
        column.key,
        ...column.aliases,
      ].map(ImportValueParsers.normalizeHeader);
      for (final key in keys) {
        final match = lookup[key];
        if (match != null) {
          mapping[column.key] = match;
          break;
        }
      }
    }
    return mapping;
  }

  ImportPreview preview({
    required DataImportKind kind,
    required String sourceFileName,
    required List<List<String>> table,
    Map<String, String>? mapping,
  }) {
    final template = DataImportTemplates.of(kind);
    if (table.isEmpty) {
      throw const FormatException('The file has no header row.');
    }
    final headers = table.first;
    final resolved = mapping ?? autoMap(template, headers);
    for (final column in template.columns.where((column) => column.required)) {
      if ((resolved[column.key] ?? '').isEmpty) {
        throw FormatException('Map a column for ${column.header}.');
      }
    }
    final headerIndex = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      headerIndex[headers[i]] = i;
    }
    final seenKeys = <String>{};
    final rows = <ImportPreviewRow>[];
    final issues = <ImportIssue>[];
    var valid = 0;
    var warnings = 0;
    var rejected = 0;
    for (var i = 1; i < table.length; i++) {
      final raw = table[i];
      if (raw.every((cell) => cell.trim().isEmpty)) continue;
      final values = <String, String>{};
      for (final column in template.columns) {
        final header = resolved[column.key];
        if (header == null) continue;
        final index = headerIndex[header];
        if (index == null || index >= raw.length) continue;
        values[column.key] = raw[index];
      }
      final rowNumber = i + 1;
      final parsed = _validateRow(
        kind: kind,
        rowNumber: rowNumber,
        values: values,
        seenKeys: seenKeys,
      );
      rows.add(
        ImportPreviewRow(
          rowNumber: rowNumber,
          status: parsed.status,
          values: values,
          issues: parsed.messages,
        ),
      );
      for (final message in parsed.messages) {
        issues.add(
          ImportIssue(
            rowNumber: rowNumber,
            message: message,
            warning: parsed.status != ImportRowStatus.rejected,
          ),
        );
      }
      switch (parsed.status) {
        case ImportRowStatus.valid:
          valid++;
        case ImportRowStatus.warning:
          valid++;
          warnings++;
        case ImportRowStatus.rejected:
          rejected++;
      }
    }
    return ImportPreview(
      kind: kind,
      sourceFileName: sourceFileName,
      mapping: resolved,
      fileHeaders: headers,
      rows: rows,
      issues: issues,
      validCount: valid,
      warningCount: warnings,
      rejectedCount: rejected,
    );
  }

  Future<ImportBatchResult> commit({
    required ImportPreview preview,
    required DuplicateImportPolicy policy,
  }) {
    return _database.transaction(() async {
      final customers = [...await _customers.watchCustomers().first];
      final products = [...await _products.watchItems().first];
      final suppliers = [...await _purchases.watchSuppliers().first];
      final invoiceNumbers = {
        for (final row in await _database.select(_database.invoices).get())
          row.invoiceNumber.trim().toLowerCase(),
      };
      var imported = 0;
      var skipped = 0;
      final errors = <ImportIssue>[
        ...preview.issues.where((issue) => !issue.warning),
      ];
      final created = <(String, int, String)>[];

      for (final row in preview.rows) {
        if (row.status == ImportRowStatus.rejected) continue;
        final outcome = await _applyRow(
          kind: preview.kind,
          policy: policy,
          values: row.values,
          customers: customers,
          products: products,
          suppliers: suppliers,
          invoiceNumbers: invoiceNumbers,
        );
        if (outcome.skipped) {
          skipped++;
          continue;
        }
        imported++;
        created.addAll(outcome.records);
      }

      final batchId = await _database
          .into(_database.importBatches)
          .insert(
            ImportBatchesCompanion.insert(
              kind: preview.kind.name,
              sourceFileName: preview.sourceFileName,
              duplicatePolicy: policy.name,
              importedCount: imported,
              skippedCount: skipped,
              rejectedCount: preview.rejectedCount,
              warningCount: Value(preview.warningCount),
              status: 'committed',
            ),
          );
      for (final record in created) {
        await _database
            .into(_database.importBatchRecords)
            .insert(
              ImportBatchRecordsCompanion.insert(
                batchId: batchId,
                recordType: record.$1,
                recordId: record.$2,
                action: record.$3,
              ),
            );
      }
      for (final issue in preview.issues) {
        await _database
            .into(_database.importBatchErrors)
            .insert(
              ImportBatchErrorsCompanion.insert(
                batchId: batchId,
                rowNumber: issue.rowNumber,
                severity: issue.warning ? 'warning' : 'error',
                message: issue.message,
              ),
            );
      }
      return ImportBatchResult(
        batchId: batchId,
        importedCount: imported,
        skippedCount: skipped,
        rejectedCount: preview.rejectedCount,
        warningCount: preview.warningCount,
        errors: errors,
      );
    });
  }

  Future<List<ImportBatchSummary>> recentBatches() async {
    final rows =
        await (_database.select(_database.importBatches)
              ..orderBy([(table) => OrderingTerm.desc(table.createdAt)])
              ..limit(20))
            .get();
    return rows
        .map(
          (row) => ImportBatchSummary(
            id: row.id,
            kind: DataImportKind.values.firstWhere(
              (kind) => kind.name == row.kind,
              orElse: () => DataImportKind.customers,
            ),
            sourceFileName: row.sourceFileName,
            duplicatePolicy: DuplicateImportPolicy.values.firstWhere(
              (policy) => policy.name == row.duplicatePolicy,
              orElse: () => DuplicateImportPolicy.skip,
            ),
            importedCount: row.importedCount,
            skippedCount: row.skippedCount,
            rejectedCount: row.rejectedCount,
            warningCount: row.warningCount,
            status: row.status,
            createdAt: row.createdAt,
          ),
        )
        .toList(growable: false);
  }

  Future<void> reverseBatch(int batchId) {
    return _database.transaction(() async {
      final batch = await (_database.select(
        _database.importBatches,
      )..where((table) => table.id.equals(batchId))).getSingle();
      if (batch.status != 'committed') {
        throw StateError('This import was already reversed.');
      }
      final records = await (_database.select(
        _database.importBatchRecords,
      )..where((table) => table.batchId.equals(batchId))).get();
      for (final record in records.reversed) {
        if (record.action != 'created') continue;
        switch (record.recordType) {
          case 'invoice':
            await _invoices.delete(record.recordId);
          case 'purchase_bill':
            await _purchases.deleteBill(record.recordId);
          case 'product':
            await _products.softDelete(record.recordId);
          case 'customer':
            await _customers.softDelete(record.recordId);
          case 'supplier':
            await _purchases.deleteSupplier(record.recordId);
        }
      }
      await (_database.update(_database.importBatches)
            ..where((table) => table.id.equals(batchId)))
          .write(const ImportBatchesCompanion(status: Value('reversed')));
    });
  }

  _RowCheck _validateRow({
    required DataImportKind kind,
    required int rowNumber,
    required Map<String, String> values,
    required Set<String> seenKeys,
  }) {
    final messages = <String>[];
    var rejected = false;
    void error(String message) {
      rejected = true;
      messages.add(message);
    }

    void warn(String message) => messages.add(message);

    switch (kind) {
      case DataImportKind.customers:
      case DataImportKind.suppliers:
        if ((values['name'] ?? '').trim().isEmpty) {
          error('Name is required.');
        }
        if (ImportValueParsers.hasInvalidGstin(values['gstin'])) {
          error('Enter a valid 15-character GSTIN.');
        }
      case DataImportKind.products:
        if ((values['name'] ?? '').trim().isEmpty) {
          error('Name is required.');
        }
        if (ImportValueParsers.parseMoneyMinor(values['price']) == null) {
          error('Sale price must be a positive amount.');
        }
        if (ImportValueParsers.parseGstBasisPoints(values['gst']) == null) {
          error('GST rate must be between 0 and 100.');
        }
        if (ImportValueParsers.hasOddHsn(values['hsn'])) {
          warn('HSN/SAC should be 4 to 8 digits.');
        }
        if (ImportValueParsers.blankToNull(values['stock']) != null) {
          if (QuantityUtils.parseScaled(values['stock']!) == null) {
            warn('Opening stock must be a number with up to three decimals.');
          }
        }
      case DataImportKind.unpaidInvoices:
      case DataImportKind.unpaidBills:
        final partyKey = kind == DataImportKind.unpaidInvoices
            ? 'customerName'
            : 'supplierName';
        final numberKey = kind == DataImportKind.unpaidInvoices
            ? 'invoiceNumber'
            : 'billNumber';
        if ((values[partyKey] ?? '').trim().isEmpty) {
          error(
            kind == DataImportKind.unpaidInvoices
                ? 'Customer name is required.'
                : 'Supplier name is required.',
          );
        }
        final number = (values[numberKey] ?? '').trim();
        if (number.isEmpty) {
          error(
            kind == DataImportKind.unpaidInvoices
                ? 'Invoice number is required.'
                : 'Bill number is required.',
          );
        } else if (!seenKeys.add('$numberKey:${number.toLowerCase()}')) {
          error('Duplicate document number in this file.');
        }
        if (ImportValueParsers.parseDate(values['date']) == null) {
          error('Date must be YYYY-MM-DD or DD/MM/YYYY.');
        }
        if (ImportValueParsers.parseMoneyMinor(values['amount']) == null ||
            ImportValueParsers.parseMoneyMinor(values['amount']) == 0) {
          error('Amount must be greater than zero.');
        }
        if (ImportValueParsers.hasInvalidGstin(values['gstin'])) {
          error('Enter a valid 15-character GSTIN.');
        }
        if (ImportValueParsers.parseGstBasisPoints(values['gst']) == null) {
          error('GST rate must be between 0 and 100.');
        }
        if (ImportValueParsers.hasOddHsn(values['hsn'])) {
          warn('HSN/SAC should be 4 to 8 digits.');
        }
      case DataImportKind.openingBalances:
        final type = (values['partyType'] ?? '').trim().toLowerCase();
        if (type.isEmpty ||
            !(type.contains('customer') ||
                type.contains('supplier') ||
                type.contains('receivable') ||
                type.contains('payable'))) {
          error('Party type must be Customer or Supplier.');
        }
        if ((values['name'] ?? '').trim().isEmpty) error('Name is required.');
        if (ImportValueParsers.parseDate(values['date']) == null) {
          error('As of date must be YYYY-MM-DD or DD/MM/YYYY.');
        }
        if (ImportValueParsers.parseMoneyMinor(values['amount']) == null ||
            ImportValueParsers.parseMoneyMinor(values['amount']) == 0) {
          error('Opening amount must be greater than zero.');
        }
        if (ImportValueParsers.hasInvalidGstin(values['gstin'])) {
          error('Enter a valid 15-character GSTIN.');
        }
        if (ImportValueParsers.blankToNull(values['stock']) != null) {
          if (QuantityUtils.parseScaled(values['stock']!) == null) {
            warn('Opening stock must be a number with up to three decimals.');
          }
        }
    }
    return _RowCheck(
      status: rejected
          ? ImportRowStatus.rejected
          : messages.isEmpty
          ? ImportRowStatus.valid
          : ImportRowStatus.warning,
      messages: messages,
    );
  }

  Future<_ApplyOutcome> _applyRow({
    required DataImportKind kind,
    required DuplicateImportPolicy policy,
    required Map<String, String> values,
    required List<CustomerModel> customers,
    required List<ProductServiceModel> products,
    required List<SupplierModel> suppliers,
    required Set<String> invoiceNumbers,
  }) async {
    final now = DateTime.now();
    switch (kind) {
      case DataImportKind.customers:
        return _upsertCustomer(
          values: values,
          policy: policy,
          customers: customers,
          now: now,
        );
      case DataImportKind.suppliers:
        return _upsertSupplier(
          values: values,
          policy: policy,
          suppliers: suppliers,
          now: now,
        );
      case DataImportKind.products:
        return _upsertProduct(
          values: values,
          policy: policy,
          products: products,
          now: now,
        );
      case DataImportKind.unpaidInvoices:
        return _createInvoice(
          values: values,
          policy: policy,
          customers: customers,
          invoiceNumbers: invoiceNumbers,
          now: now,
        );
      case DataImportKind.unpaidBills:
        return _createBill(
          values: values,
          policy: policy,
          suppliers: suppliers,
          now: now,
        );
      case DataImportKind.openingBalances:
        final type = (values['partyType'] ?? '').toLowerCase();
        final isSupplier =
            type.contains('supplier') || type.contains('payable');
        final mapped = {
          ...values,
          if (isSupplier) 'supplierName': values['name'] ?? '',
          if (!isSupplier) 'customerName': values['name'] ?? '',
          'invoiceNumber': values['reference'] ?? '',
          'billNumber': values['reference'] ?? '',
          'itemName': 'Opening balance',
          'quantity': '1',
        };
        final outcome = isSupplier
            ? await _createBill(
                values: mapped,
                policy: policy,
                suppliers: suppliers,
                now: now,
                generateNumber: true,
              )
            : await _createInvoice(
                values: mapped,
                policy: policy,
                customers: customers,
                invoiceNumbers: invoiceNumbers,
                now: now,
                generateNumber: true,
              );
        await _applyImportedOpeningByName(
          name: values['name'] ?? '',
          raw: values['stock'],
          products: products,
        );
        return outcome;
    }
  }

  Future<_ApplyOutcome> _upsertCustomer({
    required Map<String, String> values,
    required DuplicateImportPolicy policy,
    required List<CustomerModel> customers,
    required DateTime now,
  }) async {
    final name = values['name']!.trim();
    final gstin = ImportValueParsers.parseGstin(values['gstin']);
    final mobile = ImportValueParsers.blankToNull(values['mobile']);
    final match = policy == DuplicateImportPolicy.importAsNew
        ? null
        : _matchParty(
            gstin: gstin,
            mobile: mobile,
            name: name,
            gstins: [for (final row in customers) (row.id!, row.gstin)],
            mobiles: [for (final row in customers) (row.id!, row.mobile)],
            names: [for (final row in customers) (row.id!, row.name)],
            records: {for (final row in customers) row.id!: row},
          );
    if (match is CustomerModel && policy == DuplicateImportPolicy.skip) {
      return const _ApplyOutcome(skipped: true);
    }
    final saved = await _customers.save(
      CustomerModel(
        id: match is CustomerModel && policy == DuplicateImportPolicy.update
            ? match.id
            : null,
        name: name,
        companyName: ImportValueParsers.blankToNull(values['company']),
        mobile: mobile,
        email: ImportValueParsers.blankToNull(values['email']),
        gstin: gstin,
        address: ImportValueParsers.blankToNull(values['address']),
        city: ImportValueParsers.blankToNull(values['city']),
        state: ImportValueParsers.blankToNull(values['state']),
        pinCode: ImportValueParsers.blankToNull(values['pin']),
        notes: ImportValueParsers.blankToNull(values['notes']),
        createdAt: match is CustomerModel ? match.createdAt : now,
        updatedAt: now,
      ),
    );
    final existing = customers.indexWhere((row) => row.id == saved.id);
    if (existing >= 0) {
      customers[existing] = saved;
    } else {
      customers.add(saved);
    }
    return _ApplyOutcome(
      records: [
        ('customer', saved.id!, match is CustomerModel ? 'updated' : 'created'),
      ],
    );
  }

  Future<_ApplyOutcome> _upsertSupplier({
    required Map<String, String> values,
    required DuplicateImportPolicy policy,
    required List<SupplierModel> suppliers,
    required DateTime now,
  }) async {
    final name = values['name']!.trim();
    final gstin = ImportValueParsers.parseGstin(values['gstin']);
    final mobile = ImportValueParsers.blankToNull(values['mobile']);
    final match = policy == DuplicateImportPolicy.importAsNew
        ? null
        : _matchParty(
            gstin: gstin,
            mobile: mobile,
            name: name,
            gstins: [for (final row in suppliers) (row.id!, row.gstin)],
            mobiles: [for (final row in suppliers) (row.id!, row.mobile)],
            names: [for (final row in suppliers) (row.id!, row.name)],
            records: {for (final row in suppliers) row.id!: row},
          );
    if (match is SupplierModel && policy == DuplicateImportPolicy.skip) {
      return const _ApplyOutcome(skipped: true);
    }
    final saved = await _purchases.saveSupplier(
      SupplierModel(
        id: match is SupplierModel && policy == DuplicateImportPolicy.update
            ? match.id
            : null,
        name: name,
        companyName: ImportValueParsers.blankToNull(values['company']),
        mobile: mobile,
        email: ImportValueParsers.blankToNull(values['email']),
        gstin: gstin,
        gstRegistrationType: gstin == null ? 'unregistered' : 'regular',
        address: ImportValueParsers.blankToNull(values['address']),
        createdAt: match is SupplierModel ? match.createdAt : now,
        updatedAt: now,
      ),
    );
    final existing = suppliers.indexWhere((row) => row.id == saved.id);
    if (existing >= 0) {
      suppliers[existing] = saved;
    } else {
      suppliers.add(saved);
    }
    return _ApplyOutcome(
      records: [
        ('supplier', saved.id!, match is SupplierModel ? 'updated' : 'created'),
      ],
    );
  }

  Future<_ApplyOutcome> _upsertProduct({
    required Map<String, String> values,
    required DuplicateImportPolicy policy,
    required List<ProductServiceModel> products,
    required DateTime now,
  }) async {
    final name = values['name']!.trim();
    final hsn = ImportValueParsers.blankToNull(values['hsn']);
    ProductServiceModel? match;
    if (policy != DuplicateImportPolicy.importAsNew) {
      final hits = products.where((row) {
        final sameName = row.name.trim().toLowerCase() == name.toLowerCase();
        final sameHsn =
            (hsn ?? '').toLowerCase() == (row.hsnSac ?? '').toLowerCase();
        return sameName && (hsn == null || sameHsn);
      });
      if (hits.length == 1) match = hits.first;
    }
    if (match != null && policy == DuplicateImportPolicy.skip) {
      return const _ApplyOutcome(skipped: true);
    }
    final typeRaw = (values['type'] ?? '').toLowerCase();
    final saved = await _products.save(
      ProductServiceModel(
        id: match != null && policy == DuplicateImportPolicy.update
            ? match.id
            : null,
        name: name,
        type: typeRaw.contains('service') ? ItemType.service : ItemType.product,
        description: ImportValueParsers.blankToNull(values['description']),
        unit: ImportValueParsers.blankToNull(values['unit']) ?? 'Pcs',
        salePriceMinor: ImportValueParsers.parseMoneyMinor(values['price'])!,
        hsnSac: hsn,
        taxRateBasisPoints:
            ImportValueParsers.parseGstBasisPoints(values['gst']) ?? 0,
        trackStock: !typeRaw.contains('service'),
        imagePaths: match?.imagePaths ?? const [],
        createdAt: match?.createdAt ?? now,
        updatedAt: now,
      ),
    );
    final existing = products.indexWhere((row) => row.id == saved.id);
    if (existing >= 0) {
      products[existing] = saved;
    } else {
      products.add(saved);
    }
    await _applyImportedOpening(productId: saved.id!, raw: values['stock']);
    return _ApplyOutcome(
      records: [('product', saved.id!, match == null ? 'created' : 'updated')],
    );
  }

  Future<_ApplyOutcome> _createInvoice({
    required Map<String, String> values,
    required DuplicateImportPolicy policy,
    required List<CustomerModel> customers,
    required Set<String> invoiceNumbers,
    required DateTime now,
    bool generateNumber = false,
  }) async {
    var number = (values['invoiceNumber'] ?? '').trim();
    if (number.isEmpty && generateNumber) {
      number = 'OB-${now.microsecondsSinceEpoch}';
    }
    final key = number.toLowerCase();
    if (invoiceNumbers.contains(key)) {
      if (policy == DuplicateImportPolicy.skip) {
        return const _ApplyOutcome(skipped: true);
      }
      throw StateError('Invoice $number already exists.');
    }
    final customerOutcome = await _upsertCustomer(
      values: {
        'name': values['customerName'] ?? '',
        'mobile': values['mobile'] ?? '',
        'gstin': values['gstin'] ?? '',
      },
      policy: policy == DuplicateImportPolicy.importAsNew
          ? DuplicateImportPolicy.importAsNew
          : DuplicateImportPolicy.skip,
      customers: customers,
      now: now,
    );
    final CustomerModel? customer;
    if (customerOutcome.records.isEmpty) {
      customer = _matchParty(
        gstin: ImportValueParsers.parseGstin(values['gstin']),
        mobile: ImportValueParsers.blankToNull(values['mobile']),
        name: (values['customerName'] ?? '').trim(),
        gstins: [for (final row in customers) (row.id!, row.gstin)],
        mobiles: [for (final row in customers) (row.id!, row.mobile)],
        names: [for (final row in customers) (row.id!, row.name)],
        records: {for (final row in customers) row.id!: row},
      );
    } else {
      customer = customers.firstWhere(
        (row) => row.id == customerOutcome.records.first.$2,
      );
    }
    if (customer == null) {
      throw StateError('Customer could not be resolved.');
    }
    final amount = ImportValueParsers.parseMoneyMinor(values['amount'])!;
    final gst = ImportValueParsers.parseGstBasisPoints(values['gst']) ?? 0;
    final quantity =
        ImportValueParsers.parseQuantityScaled(values['quantity']) ?? 1000;
    final item = InvoiceItemModel(
      localId: 'import-$number',
      name:
          ImportValueParsers.blankToNull(values['itemName']) ??
          'Opening balance',
      quantityScaled: quantity,
      unit: 'Pcs',
      rateMinor: amount,
      hsnSac: ImportValueParsers.blankToNull(values['hsn']),
      taxRateBasisPoints: gst,
      discount: const DiscountInput.none(),
    );
    final taxType = _taxType(values['taxMode'], gst);
    final calculation = _calculation.calculate(
      InvoiceCalculationInput(
        items: [
          InvoiceCalculationItemInput(
            id: item.localId,
            quantityScaled: item.quantityScaled,
            rateMinor: item.rateMinor,
            taxRateBasisPoints: item.taxRateBasisPoints,
          ),
        ],
        taxType: taxType,
      ),
    );
    final saved = await _invoices.save(
      InvoiceModel(
        invoiceNumber: number,
        customer: CustomerSnapshotModel.fromCustomer(customer),
        invoiceDate: ImportValueParsers.parseDate(values['date'])!,
        dueDate: ImportValueParsers.parseDate(values['dueDate']),
        status: InvoiceStatus.unpaid,
        taxType: taxType,
        invoiceDiscount: const DiscountInput.none(),
        items: [item],
        charges: const [],
        calculation: calculation,
        notes: ImportValueParsers.blankToNull(values['notes']),
        createdAt: now,
        updatedAt: now,
      ),
    );
    invoiceNumbers.add(key);
    return _ApplyOutcome(
      records: [...customerOutcome.records, ('invoice', saved.id!, 'created')],
    );
  }

  Future<_ApplyOutcome> _createBill({
    required Map<String, String> values,
    required DuplicateImportPolicy policy,
    required List<SupplierModel> suppliers,
    required DateTime now,
    bool generateNumber = false,
  }) async {
    var number = (values['billNumber'] ?? '').trim();
    if (number.isEmpty && generateNumber) {
      number = 'OB-${now.microsecondsSinceEpoch}';
    }
    final available = await _purchases.isBillNumberAvailable(number);
    if (!available) {
      if (policy == DuplicateImportPolicy.skip) {
        return const _ApplyOutcome(skipped: true);
      }
      throw StateError('Bill $number already exists.');
    }
    final supplierOutcome = await _upsertSupplier(
      values: {
        'name': values['supplierName'] ?? '',
        'mobile': values['mobile'] ?? '',
        'gstin': values['gstin'] ?? '',
      },
      policy: policy == DuplicateImportPolicy.importAsNew
          ? DuplicateImportPolicy.importAsNew
          : DuplicateImportPolicy.skip,
      suppliers: suppliers,
      now: now,
    );
    final SupplierModel? supplier;
    if (supplierOutcome.records.isEmpty) {
      supplier = _matchParty(
        gstin: ImportValueParsers.parseGstin(values['gstin']),
        mobile: ImportValueParsers.blankToNull(values['mobile']),
        name: (values['supplierName'] ?? '').trim(),
        gstins: [for (final row in suppliers) (row.id!, row.gstin)],
        mobiles: [for (final row in suppliers) (row.id!, row.mobile)],
        names: [for (final row in suppliers) (row.id!, row.name)],
        records: {for (final row in suppliers) row.id!: row},
      );
    } else {
      supplier = suppliers.firstWhere(
        (row) => row.id == supplierOutcome.records.first.$2,
      );
    }
    if (supplier == null) {
      throw StateError('Supplier could not be resolved.');
    }
    final amount = ImportValueParsers.parseMoneyMinor(values['amount'])!;
    final gst = ImportValueParsers.parseGstBasisPoints(values['gst']) ?? 0;
    final quantityScaled =
        ImportValueParsers.parseQuantityScaled(values['quantity']) ?? 1000;
    final item = PurchaseItemModel(
      name:
          ImportValueParsers.blankToNull(values['itemName']) ??
          'Opening balance',
      quantity: quantityScaled / 1000,
      unit: 'Pcs',
      hsnSac: ImportValueParsers.blankToNull(values['hsn']),
      rateMinor: amount,
      taxRate: gst / 100,
    );
    final billId = await _purchases.saveBill(
      PurchaseBillModel(
        billNumber: number,
        supplierId: supplier.id,
        supplierName: supplier.name,
        billDate: ImportValueParsers.parseDate(values['date'])!,
        dueDate: ImportValueParsers.parseDate(values['dueDate']),
        items: [item],
        notes: ImportValueParsers.blankToNull(values['notes']),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return _ApplyOutcome(
      records: [
        ...supplierOutcome.records,
        ('purchase_bill', billId, 'created'),
      ],
    );
  }

  Future<void> _applyImportedOpening({
    required int productId,
    required String? raw,
  }) async {
    if (ImportValueParsers.blankToNull(raw) == null) return;
    final qty = QuantityUtils.parseScaled(raw!) ?? 0;
    await StockLedger(_database).replaceSource(
      sourceType: StockSourceType.opening,
      sourceId: productId,
      type: StockMovementType.opening,
      lines: [
        if (qty > 0) StockLine(productId: productId, quantityScaled: qty),
      ],
    );
  }

  Future<void> _applyImportedOpeningByName({
    required String name,
    required String? raw,
    required List<ProductServiceModel> products,
  }) async {
    if (ImportValueParsers.blankToNull(raw) == null) return;
    final needle = name.trim().toLowerCase();
    if (needle.isEmpty) return;
    final hits = products
        .where(
          (row) =>
              row.type == ItemType.product &&
              row.id != null &&
              row.name.trim().toLowerCase() == needle,
        )
        .toList(growable: false);
    if (hits.length != 1) return;
    await _applyImportedOpening(productId: hits.single.id!, raw: raw);
  }

  T? _matchParty<T>({
    required String? gstin,
    required String? mobile,
    required String name,
    required List<(int, String?)> gstins,
    required List<(int, String?)> mobiles,
    required List<(int, String)> names,
    required Map<int, T> records,
  }) {
    if (gstin != null) {
      final hits = gstins
          .where((row) => (row.$2 ?? '').toUpperCase() == gstin)
          .map((row) => row.$1)
          .toSet();
      if (hits.length == 1) return records[hits.first];
    }
    final digits = (mobile ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      final hits = mobiles
          .where(
            (row) => (row.$2 ?? '').replaceAll(RegExp(r'\D'), '') == digits,
          )
          .map((row) => row.$1)
          .toSet();
      if (hits.length == 1) return records[hits.first];
    }
    final hits = names
        .where((row) => row.$2.trim().toLowerCase() == name.toLowerCase())
        .map((row) => row.$1)
        .toSet();
    if (hits.length == 1) return records[hits.first];
    return null;
  }

  TaxType _taxType(String? raw, int gst) {
    final value = (raw ?? '').toLowerCase();
    if (value.contains('igst')) return TaxType.igst;
    if (value.contains('none') || value.contains('exempt') || gst <= 0) {
      return TaxType.none;
    }
    return TaxType.cgstSgst;
  }
}

class _RowCheck {
  const _RowCheck({required this.status, required this.messages});
  final ImportRowStatus status;
  final List<String> messages;
}

class _ApplyOutcome {
  const _ApplyOutcome({this.skipped = false, this.records = const []});
  final bool skipped;
  final List<(String, int, String)> records;
}
