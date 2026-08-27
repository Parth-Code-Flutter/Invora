import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/services/expense_pdf_service.dart';

class ExpenseListController extends GetxController {
  ExpenseListController(this._expenses);
  final ExpenseRepository _expenses;

  final query = ''.obs;
  final thisMonthOnly = false.obs;
  final items = <ExpenseSummaryModel>[].obs;
  StreamSubscription<List<ExpenseSummaryModel>>? _subscription;

  List<ExpenseSummaryModel> get visible {
    final needle = query.value.trim().toLowerCase();
    final now = DateTime.now();
    return items
        .where((item) {
          if (thisMonthOnly.value &&
              (item.expenseDate.year != now.year ||
                  item.expenseDate.month != now.month)) {
            return false;
          }
          if (needle.isEmpty) return true;
          return item.payee.toLowerCase().contains(needle) ||
              item.category.toLowerCase().contains(needle) ||
              item.expenseNumber.toLowerCase().contains(needle);
        })
        .toList(growable: false);
  }

  int get monthTotalMinor {
    final now = DateTime.now();
    return items.fold<int>(0, (sum, item) {
      if (item.isCancelled) return sum;
      if (item.expenseDate.year != now.year ||
          item.expenseDate.month != now.month) {
        return sum;
      }
      return sum + item.grandTotalMinor;
    });
  }

  @override
  void onInit() {
    super.onInit();
    _subscription = _expenses.watchAll().listen(items.assignAll);
  }

  void search(String value) => query.value = value;

  void toggleThisMonth(bool value) => thisMonthOnly.value = value;

  void openCreate() => Get.toNamed<void>(AppRoutes.expenseCreate);

  void openDetails(ExpenseSummaryModel item) =>
      Get.toNamed<void>(AppRoutes.expenseDetails, arguments: item.id);

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}

class ExpenseFormController extends GetxController {
  ExpenseFormController(this._expenses);
  final ExpenseRepository _expenses;

  final payee = TextEditingController();
  final amount = TextEditingController();
  final notes = TextEditingController();
  final category = ExpenseMath.categories.first.obs;
  final paymentMethod = 'Cash'.obs;
  final taxRateBasisPoints = 0.obs;
  final itcEligible = false.obs;
  final date = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  ).obs;
  final isSaving = false.obs;
  final dirty = false.obs;
  ExpenseModel? _existing;

  bool get isEditing => _existing != null;

  ExpenseSplit get split {
    final paid = CurrencyUtils.parseMinor(amount.text) ?? 0;
    return ExpenseMath.split(
      paidMinor: paid,
      taxRateBasisPoints: taxRateBasisPoints.value,
    );
  }

  @override
  void onInit() {
    super.onInit();
    final id = Get.arguments;
    if (id is int) {
      _load(id);
    }
    payee.addListener(_markDirty);
    amount.addListener(_markDirty);
    notes.addListener(_markDirty);
  }

  void _markDirty() => dirty.value = true;

  Future<void> _load(int id) async {
    final model = await _expenses.getById(id);
    if (model == null) return;
    _existing = model;
    payee.text = model.payee;
    amount.text = CurrencyUtils.toInputValue(model.grandTotalMinor);
    notes.text = model.notes ?? '';
    category.value = ExpenseMath.categories.contains(model.category)
        ? model.category
        : 'Other';
    paymentMethod.value =
        ExpenseMath.paymentMethods.contains(model.paymentMethod)
        ? model.paymentMethod
        : 'Other';
    taxRateBasisPoints.value = model.taxRateBasisPoints;
    itcEligible.value = model.itcEligible;
    date.value = DateTime(
      model.expenseDate.year,
      model.expenseDate.month,
      model.expenseDate.day,
    );
    dirty.value = false;
  }

  void setCategory(String value) {
    category.value = value;
    dirty.value = true;
  }

  void setPaymentMethod(String value) {
    paymentMethod.value = value;
    dirty.value = true;
  }

  void setTaxRate(int value) {
    taxRateBasisPoints.value = value;
    if (value <= 0) itcEligible.value = false;
    dirty.value = true;
  }

  void setItc(bool value) {
    itcEligible.value = value;
    dirty.value = true;
  }

  void setDate(DateTime value) {
    date.value = DateTime(value.year, value.month, value.day);
    dirty.value = true;
  }

  Future<bool> save({bool pop = true}) async {
    if (isSaving.value) return false;
    isSaving.value = true;
    try {
      final paid = CurrencyUtils.parseMinor(amount.text);
      if (paid == null || paid <= 0) {
        AppNotification.warning(
          'Cannot save expense',
          'Enter an amount greater than zero.',
        );
        return false;
      }
      final now = DateTime.now();
      await _expenses.save(
        ExpenseModel(
          id: _existing?.id,
          expenseNumber: _existing?.expenseNumber ?? '',
          expenseDate: date.value,
          category: category.value,
          payee: payee.text,
          amountMinor: paid,
          taxRateBasisPoints: taxRateBasisPoints.value,
          grandTotalMinor: paid,
          itcEligible: itcEligible.value,
          paymentMethod: paymentMethod.value,
          notes: notes.text,
          createdAt: _existing?.createdAt ?? now,
          updatedAt: now,
        ),
      );
      dirty.value = false;
      if (pop) Get.back<void>();
      AppNotification.success(
        isEditing ? 'Expense updated' : 'Expense recorded',
        isEditing
            ? 'The voucher was updated.'
            : 'The expense was saved offline.',
      );
      return true;
    } on ArgumentError catch (error) {
      AppNotification.warning('Cannot save expense', error.message.toString());
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    payee.dispose();
    amount.dispose();
    notes.dispose();
    super.onClose();
  }
}

class ExpenseDetailsController extends GetxController {
  ExpenseDetailsController(this._expenses, this._business, this._pdf);
  final ExpenseRepository _expenses;
  final BusinessRepository _business;
  final ExpensePdfService _pdf;

  final expense = Rxn<ExpenseModel>();
  final currencySymbol = '₹'.obs;

  @override
  void onInit() {
    super.onInit();
    final id = Get.arguments;
    if (id is int) {
      _load(id);
    }
  }

  Future<void> _load(int id) async {
    expense.value = await _expenses.getById(id);
    final profile = await _business.getProfile();
    currencySymbol.value = profile?.currencySymbol ?? '₹';
  }

  Future<void> openEdit() async {
    final current = expense.value;
    if (current == null || current.isCancelled || current.id == null) return;
    await Get.toNamed<void>(AppRoutes.expenseEdit, arguments: current.id);
    await _load(current.id!);
  }

  Future<void> cancel(String reason) async {
    final current = expense.value;
    if (current?.id == null) return;
    try {
      expense.value = await _expenses.cancel(id: current!.id!, reason: reason);
      AppNotification.success(
        'Expense cancelled',
        'It stays on file and is excluded from totals.',
      );
    } on ArgumentError catch (error) {
      AppNotification.warning(
        'Cannot cancel expense',
        error.message.toString(),
      );
    }
  }

  Future<void> share() async {
    final current = expense.value;
    final profile = await _business.getProfile();
    if (current == null || profile == null) return;
    await _pdf.share(expense: current, business: profile);
  }

  Future<void> printPdf() async {
    final current = expense.value;
    final profile = await _business.getProfile();
    if (current == null || profile == null) return;
    await _pdf.print(expense: current, business: profile);
  }

  Future<void> savePdf() async {
    final current = expense.value;
    final profile = await _business.getProfile();
    if (current == null || profile == null) return;
    await _pdf.save(expense: current, business: profile);
  }
}
