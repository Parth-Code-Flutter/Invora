enum ExpenseStatus { recorded, cancelled }

class ExpenseSplit {
  const ExpenseSplit({
    required this.taxableMinor,
    required this.taxMinor,
    required this.grandTotalMinor,
  });

  final int taxableMinor;
  final int taxMinor;
  final int grandTotalMinor;
}

/// Amount is what was paid. GST, if any, is treated as inclusive.
abstract final class ExpenseMath {
  static const categories = [
    'Rent',
    'Electricity',
    'Salary',
    'Travel',
    'Fuel',
    'Office',
    'Marketing',
    'Repair',
    'Professional fees',
    'Other',
  ];

  static const paymentMethods = ['Cash', 'UPI', 'Bank', 'Card', 'Other'];

  static ExpenseSplit split({
    required int paidMinor,
    required int taxRateBasisPoints,
  }) {
    final paid = paidMinor < 0 ? 0 : paidMinor;
    if (taxRateBasisPoints <= 0) {
      return ExpenseSplit(
        taxableMinor: paid,
        taxMinor: 0,
        grandTotalMinor: paid,
      );
    }
    final taxable = ((paid * 10000) / (10000 + taxRateBasisPoints)).round();
    return ExpenseSplit(
      taxableMinor: taxable,
      taxMinor: paid - taxable,
      grandTotalMinor: paid,
    );
  }

  static ExpenseStatus statusFrom(String value) =>
      value == ExpenseStatus.cancelled.name
      ? ExpenseStatus.cancelled
      : ExpenseStatus.recorded;
}

class ExpenseModel {
  const ExpenseModel({
    this.id,
    required this.expenseNumber,
    required this.expenseDate,
    required this.category,
    required this.payee,
    required this.amountMinor,
    this.taxRateBasisPoints = 0,
    this.taxMinor = 0,
    this.taxableMinor = 0,
    required this.grandTotalMinor,
    this.itcEligible = false,
    this.paymentMethod = 'Cash',
    this.notes,
    this.status = ExpenseStatus.recorded,
    this.cancellationReason,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String expenseNumber;
  final DateTime expenseDate;
  final String category;
  final String payee;
  final int amountMinor;
  final int taxRateBasisPoints;
  final int taxMinor;
  final int taxableMinor;
  final int grandTotalMinor;
  final bool itcEligible;
  final String paymentMethod;
  final String? notes;
  final ExpenseStatus status;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCancelled => status == ExpenseStatus.cancelled;
}

class ExpenseSummaryModel {
  const ExpenseSummaryModel({
    required this.id,
    required this.expenseNumber,
    required this.expenseDate,
    required this.category,
    required this.payee,
    required this.grandTotalMinor,
    required this.status,
  });

  final int id;
  final String expenseNumber;
  final DateTime expenseDate;
  final String category;
  final String payee;
  final int grandTotalMinor;
  final ExpenseStatus status;

  bool get isCancelled => status == ExpenseStatus.cancelled;
}
