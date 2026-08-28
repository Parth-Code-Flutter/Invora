import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../data/models/cash_book_models.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/purchase_models.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/cash_book_repository.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/purchase_repository.dart';

class CashBookController extends GetxController {
  CashBookController(
    this._cashBook,
    this._business,
    this._customers,
    this._purchases,
  );

  final CashBookRepository _cashBook;
  final BusinessRepository _business;
  final CustomerRepository _customers;
  final PurchaseRepository _purchases;

  final snapshot = const CashBookSnapshot(accounts: [], advances: []).obs;
  final customers = <CustomerModel>[].obs;
  final suppliers = <SupplierModel>[].obs;
  final currencySymbol = '₹'.obs;
  StreamSubscription<CashBookSnapshot>? _subscription;

  List<MoneyAccountModel> get accounts => snapshot.value.active;
  MoneyAccountModel? get cashAccount =>
      accounts.where((account) => account.isCash).firstOrNull;

  @override
  void onInit() {
    super.onInit();
    _business.getProfile().then(
      (profile) => currencySymbol.value = profile?.currencySymbol ?? '₹',
    );
    _subscription = _cashBook.watchSnapshot().listen(
      (value) => snapshot.value = value,
    );
    _customers.watchCustomers().listen(customers.assignAll);
    _purchases.watchSuppliers().listen(suppliers.assignAll);
  }

  void openStatement(MoneyAccountModel account) {
    Get.toNamed<void>(AppRoutes.cashBookStatement, arguments: account.id);
  }

  void openAdvance({CashBookAdvanceArgs? args}) {
    Get.toNamed<void>(AppRoutes.cashBookAdvance, arguments: args);
  }

  Future<String?> saveAccount({
    int? id,
    required String name,
    required MoneyAccountType type,
    String opening = '',
  }) async {
    try {
      final openingMinor = opening.trim().isEmpty
          ? 0
          : CurrencyUtils.parseMinor(opening);
      if (openingMinor == null || openingMinor < 0) {
        return 'Enter a valid opening amount.';
      }
      await _cashBook.saveAccount(
        id: id,
        name: name,
        type: type,
        openingMinor: openingMinor,
      );
      AppNotification.success(
        id == null ? 'Account added' : 'Account updated',
        'The cash book now uses this account.',
      );
      return null;
    } on ArgumentError catch (error) {
      return error.message?.toString() ?? 'Could not save the account.';
    } on StateError catch (error) {
      return error.message;
    }
  }

  Future<String?> archive(
    MoneyAccountModel account, {
    required bool archived,
  }) async {
    try {
      await _cashBook.archiveAccount(account.id!, archived: archived);
      return null;
    } on StateError catch (error) {
      return error.message;
    }
  }

  Future<String?> transfer({
    required int fromAccountId,
    required int toAccountId,
    required String amount,
    required DateTime date,
    String? note,
  }) async {
    try {
      final minor = CurrencyUtils.parseMinor(amount);
      if (minor == null || minor <= 0) {
        return 'Enter a transfer greater than zero.';
      }
      await _cashBook.transfer(
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        amountMinor: minor,
        occurredAt: date,
        note: note,
      );
      AppNotification.success(
        'Transfer recorded',
        'Both accounts now show the movement.',
      );
      return null;
    } on ArgumentError catch (error) {
      return error.message?.toString() ?? 'Could not transfer.';
    }
  }

  Future<String?> closeCash({required String counted, String? note}) async {
    final cash = cashAccount;
    if (cash?.id == null) return 'Add a cash account first.';
    try {
      final minor = CurrencyUtils.parseMinor(counted);
      if (minor == null || minor < 0) {
        return 'Enter the cash you counted.';
      }
      await _cashBook.closeCash(
        accountId: cash!.id!,
        date: DateTime.now(),
        countedMinor: minor,
        note: note,
      );
      AppNotification.success(
        'Cash closed',
        'Today’s cash count is saved in the book.',
      );
      return null;
    } on ArgumentError catch (error) {
      return error.message?.toString() ?? 'Could not close cash.';
    } on StateError catch (error) {
      return error.message;
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}

enum StatementRangePreset { thisMonth, lastMonth, all, custom }

class AccountStatementController extends GetxController {
  AccountStatementController(this._cashBook, this._business);

  final CashBookRepository _cashBook;
  final BusinessRepository _business;
  final movements = <MoneyMovementModel>[].obs;
  final account = Rxn<MoneyAccountModel>();
  final currencySymbol = '₹'.obs;
  final from = DateTime(DateTime.now().year, DateTime.now().month, 1).obs;
  final to = DateTime.now().obs;
  final rangePreset = StatementRangePreset.thisMonth.obs;
  StreamSubscription<List<MoneyMovementModel>>? _subscription;

  int get accountId => Get.arguments as int;

  @override
  void onInit() {
    super.onInit();
    _business.getProfile().then(
      (profile) => currencySymbol.value = profile?.currencySymbol ?? '₹',
    );
    _load();
  }

  Future<void> _load() async {
    await _reloadAccount();
    _watch();
  }

  Future<void> _reloadAccount() async {
    final accounts = await _cashBook.listAccounts(includeArchived: true);
    account.value = accounts.where((item) => item.id == accountId).firstOrNull;
  }

  void applyRange(StatementRangePreset preset) {
    final now = DateTime.now();
    rangePreset.value = preset;
    switch (preset) {
      case StatementRangePreset.thisMonth:
        from.value = DateTime(now.year, now.month, 1);
        to.value = now;
      case StatementRangePreset.lastMonth:
        from.value = DateTime(now.year, now.month - 1, 1);
        to.value = DateTime(now.year, now.month, 0);
      case StatementRangePreset.all:
        from.value = DateTime(2000, 1, 1);
        to.value = now;
      case StatementRangePreset.custom:
        break;
    }
    _watch();
  }

  void setFrom(DateTime value) {
    from.value = value;
    rangePreset.value = StatementRangePreset.custom;
    _watch();
  }

  void setTo(DateTime value) {
    to.value = value;
    rangePreset.value = StatementRangePreset.custom;
    _watch();
  }

  void _watch() {
    _subscription?.cancel();
    _subscription = _cashBook
        .watchStatement(accountId, from: from.value, to: to.value)
        .listen(movements.assignAll);
  }

  Future<String?> clearCheque(MoneyMovementModel movement) async {
    try {
      await _cashBook.clearCheque(movement.id);
      await _reloadAccount();
      AppNotification.success(
        'Cheque cleared',
        'Available balance now includes it.',
      );
      return null;
    } on StateError catch (error) {
      return error.message;
    }
  }

  Future<String?> bounceCheque(
    MoneyMovementModel movement,
    String reason,
  ) async {
    try {
      await _cashBook.bounceCheque(movement.id, reason: reason);
      await _reloadAccount();
      AppNotification.success(
        'Cheque bounced',
        'The original document was reversed to keep the books even.',
      );
      return null;
    } on ArgumentError catch (error) {
      return error.message?.toString() ?? 'Could not bounce the cheque.';
    } on StateError catch (error) {
      return error.message;
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}

class AdvanceFormController extends GetxController {
  AdvanceFormController(this._cashBook, this._customers, this._purchases);

  final CashBookRepository _cashBook;
  final CustomerRepository _customers;
  final PurchaseRepository _purchases;

  final partyType = PartyKind.customer.obs;
  final partyId = Rxn<int>();
  final partyName = ''.obs;
  final accountId = Rxn<int>();
  final amount = TextEditingController();
  final note = TextEditingController();
  final method = 'UPI'.obs;
  final accounts = <MoneyAccountModel>[].obs;
  final customers = <CustomerModel>[].obs;
  final suppliers = <SupplierModel>[].obs;
  final openAdvances = <PartyAdvanceModel>[].obs;
  final allocatable = <AllocatableDocument>[].obs;
  final selectedAdvanceId = Rxn<int>();
  DateTime date = DateTime.now();
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is CashBookAdvanceArgs) {
      if (args.partyType != null) partyType.value = args.partyType!;
      partyId.value = args.partyId;
      partyName.value = args.partyName ?? '';
    }
    _load();
  }

  Future<void> _load() async {
    accounts.assignAll(await _cashBook.activeAccounts());
    accountId.value ??= accounts.firstOrNull?.id;
    customers.assignAll(await _customers.watchCustomers().first);
    suppliers.assignAll(await _purchases.watchSuppliers().first);
    if (partyId.value == null) {
      if (partyType.value == PartyKind.customer && customers.isNotEmpty) {
        selectParty(id: customers.first.id!, name: customers.first.name);
      } else if (partyType.value == PartyKind.supplier &&
          suppliers.isNotEmpty) {
        selectParty(id: suppliers.first.id!, name: suppliers.first.name);
      } else {
        await refreshAdvances();
      }
    } else {
      await refreshAdvances();
    }
  }

  Future<void> refreshAdvances() async {
    openAdvances.assignAll(
      await _cashBook.listOpenAdvances(
        partyType: partyType.value,
        partyId: partyId.value,
      ),
    );
    selectedAdvanceId.value = openAdvances.firstOrNull?.id;
    await loadAllocatable();
  }

  void selectPartyType(PartyKind type) {
    partyType.value = type;
    partyId.value = null;
    partyName.value = '';
    refreshAdvances();
  }

  void selectParty({required int id, required String name}) {
    partyId.value = id;
    partyName.value = name;
    refreshAdvances();
  }

  Future<void> loadAllocatable() async {
    final id = selectedAdvanceId.value;
    if (id == null) {
      allocatable.clear();
      return;
    }
    final advance = openAdvances.where((item) => item.id == id).firstOrNull;
    if (advance == null) {
      allocatable.clear();
      return;
    }
    allocatable.assignAll(await _cashBook.allocatableDocuments(advance));
  }

  Future<String?> saveAdvance() async {
    if (partyId.value == null) return 'Choose a customer or supplier.';
    if (accountId.value == null) return 'Choose an account.';
    final minor = CurrencyUtils.parseMinor(amount.text);
    if (minor == null || minor <= 0) {
      return 'Enter an advance greater than zero.';
    }
    isSaving.value = true;
    try {
      await _cashBook.recordAdvance(
        partyType: partyType.value,
        partyId: partyId.value!,
        partyName: partyName.value,
        accountId: accountId.value!,
        amountMinor: minor,
        occurredAt: date,
        note: note.text,
        method: method.value,
      );
      AppNotification.success(
        'Advance recorded',
        'Allocate it to an invoice or bill when you are ready.',
      );
      amount.clear();
      await refreshAdvances();
      return null;
    } on ArgumentError catch (error) {
      return error.message?.toString() ?? 'Could not record the advance.';
    } finally {
      isSaving.value = false;
    }
  }

  Future<String?> allocate({
    required int documentId,
    required String amountInput,
  }) async {
    final advanceId = selectedAdvanceId.value;
    if (advanceId == null) return 'Choose an advance first.';
    final minor = CurrencyUtils.parseMinor(amountInput);
    if (minor == null || minor <= 0) {
      return 'Enter an amount to apply.';
    }
    try {
      await _cashBook.allocateAdvance(
        advanceId: advanceId,
        documentId: documentId,
        amountMinor: minor,
      );
      AppNotification.success(
        'Advance applied',
        'The document balance went down. Cash did not move again.',
      );
      await refreshAdvances();
      return null;
    } on ArgumentError catch (error) {
      return error.message?.toString() ?? 'Could not apply the advance.';
    } on StateError catch (error) {
      return error.message;
    }
  }

  Future<String?> refund(String reason) async {
    final advanceId = selectedAdvanceId.value;
    if (advanceId == null) return 'Choose an advance first.';
    try {
      await _cashBook.refundAdvance(advanceId, reason: reason);
      AppNotification.success(
        'Advance refunded',
        'The leftover left the cash book.',
      );
      await refreshAdvances();
      return null;
    } on ArgumentError catch (error) {
      return error.message?.toString() ?? 'Could not refund the advance.';
    } on StateError catch (error) {
      return error.message;
    }
  }

  @override
  void onClose() {
    amount.dispose();
    note.dispose();
    super.onClose();
  }
}
