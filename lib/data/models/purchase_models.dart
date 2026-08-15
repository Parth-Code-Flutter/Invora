class SupplierModel {
  const SupplierModel({
    this.id,
    required this.name,
    this.companyName,
    this.mobile,
    this.email,
    this.gstin,
    this.address,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });
  final int? id;
  final String name;
  final String? companyName, mobile, email, gstin, address;
  final bool isDeleted;
  final DateTime createdAt, updatedAt;
}

class PurchaseItemModel {
  const PurchaseItemModel({
    this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.rateMinor,
    this.taxRate = 0,
  });
  final int? id;
  final String name, unit;
  final double quantity, taxRate;
  final int rateMinor;
  int get subtotalMinor => (quantity * rateMinor).round();
  int get taxMinor => (subtotalMinor * taxRate / 100).round();
  int get totalMinor => subtotalMinor + taxMinor;
}

class PurchaseBillModel {
  const PurchaseBillModel({
    this.id,
    required this.billNumber,
    required this.supplierId,
    required this.supplierName,
    required this.billDate,
    this.dueDate,
    required this.items,
    this.paidMinor = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  final int? id, supplierId;
  final String billNumber, supplierName;
  final DateTime billDate, createdAt, updatedAt;
  final DateTime? dueDate;
  final List<PurchaseItemModel> items;
  final int paidMinor;
  final String? notes;
  int get subtotalMinor =>
      items.fold(0, (sum, item) => sum + item.subtotalMinor);
  int get taxMinor => items.fold(0, (sum, item) => sum + item.taxMinor);
  int get totalMinor => subtotalMinor + taxMinor;
  int get balanceMinor => (totalMinor - paidMinor).clamp(0, totalMinor);
}

class PurchaseBillSummary {
  const PurchaseBillSummary({
    required this.id,
    required this.billNumber,
    required this.supplierName,
    required this.billDate,
    this.dueDate,
    required this.totalMinor,
    required this.paidMinor,
    required this.balanceMinor,
    required this.status,
  });
  final int id, totalMinor, paidMinor, balanceMinor;
  final String billNumber, supplierName, status;
  final DateTime billDate;
  final DateTime? dueDate;
}

class PurchasePaymentModel {
  const PurchasePaymentModel({
    required this.id,
    required this.amountMinor,
    this.method,
    this.note,
    required this.paidAt,
  });
  final int id, amountMinor;
  final String? method, note;
  final DateTime paidAt;
}

class PurchaseDashboardSummary {
  const PurchaseDashboardSummary({
    required this.totalSpendMinor,
    required this.paidMinor,
    required this.payableMinor,
    required this.overdueMinor,
    required this.billCount,
    required this.supplierCount,
  });
  final int totalSpendMinor,
      paidMinor,
      payableMinor,
      overdueMinor,
      billCount,
      supplierCount;
}
