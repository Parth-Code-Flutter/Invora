import 'product_service_model.dart';

class SupplierModel {
  const SupplierModel({
    this.id,
    required this.name,
    this.companyName,
    this.mobile,
    this.email,
    this.gstRegistrationType = 'unregistered',
    this.gstin,
    this.address,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });
  final int? id;
  final String name;
  final String gstRegistrationType;
  final String? companyName, mobile, email, gstin, address;
  final bool isDeleted;
  final DateTime createdAt, updatedAt;
}

class PurchaseItemModel {
  const PurchaseItemModel({
    this.id,
    this.productId,
    required this.name,
    required this.quantity,
    required this.unit,
    this.hsnSac,
    required this.rateMinor,
    this.taxRate = 0,
  });

  factory PurchaseItemModel.fromCatalog(
    ProductServiceModel product, {
    double quantity = 1,
  }) => PurchaseItemModel(
    productId: product.id,
    name: product.name,
    quantity: quantity,
    unit: product.unit,
    hsnSac: product.hsnSac,
    rateMinor: product.salePriceMinor,
    taxRate: product.taxRateBasisPoints / 100,
  );

  final int? id;
  final int? productId;
  final String name, unit;
  final String? hsnSac;
  final double quantity, taxRate;
  final int rateMinor;
  int get subtotalMinor => (quantity * rateMinor).round();
  int get taxMinor => (subtotalMinor * taxRate / 100).round();
  int get totalMinor => subtotalMinor + taxMinor;

  PurchaseItemModel copyWith({
    int? id,
    int? productId,
    String? name,
    double? quantity,
    String? unit,
    String? hsnSac,
    int? rateMinor,
    double? taxRate,
  }) => PurchaseItemModel(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    name: name ?? this.name,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    hsnSac: hsnSac ?? this.hsnSac,
    rateMinor: rateMinor ?? this.rateMinor,
    taxRate: taxRate ?? this.taxRate,
  );
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
    this.status = 'unpaid',
    this.cancellationReason,
    this.cancelledAt,
    this.placeOfSupply,
    this.taxMode = 'cgst_sgst',
    this.reverseCharge = false,
    this.itcEligible = true,
    this.discountMinor = 0,
    this.additionalChargesMinor = 0,
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
  final String status;
  final String? cancellationReason, placeOfSupply;
  final DateTime? cancelledAt;
  final String taxMode;
  final bool reverseCharge, itcEligible;
  final int discountMinor, additionalChargesMinor;
  int get subtotalMinor =>
      items.fold(0, (sum, item) => sum + item.subtotalMinor);
  int get taxMinor => items.fold(0, (sum, item) => sum + item.taxMinor);
  int get totalMinor =>
      (subtotalMinor + taxMinor - discountMinor + additionalChargesMinor).clamp(
        0,
        1 << 62,
      );
  int get balanceMinor => (totalMinor - paidMinor).clamp(0, totalMinor);
}

class PurchaseBillSummary {
  const PurchaseBillSummary({
    required this.id,
    required this.billNumber,
    required this.supplierId,
    required this.supplierName,
    required this.billDate,
    this.dueDate,
    required this.totalMinor,
    required this.paidMinor,
    required this.balanceMinor,
    required this.status,
  });
  final int id, supplierId, totalMinor, paidMinor, balanceMinor;
  final String billNumber, supplierName, status;
  final DateTime billDate;
  final DateTime? dueDate;
}

class PurchasePaymentModel {
  const PurchasePaymentModel({
    required this.id,
    required this.amountMinor,
    this.method,
    this.reference,
    this.note,
    this.entryType = 'payment',
    this.reversesPaymentId,
    required this.paidAt,
  });
  final int id, amountMinor;
  final String? method, reference, note;
  final String entryType;
  final int? reversesPaymentId;
  final DateTime paidAt;
}

class PurchaseBillAttachmentModel {
  const PurchaseBillAttachmentModel({
    this.id,
    required this.purchaseBillId,
    required this.fileName,
    required this.localPath,
    this.mimeType,
    this.sizeBytes = 0,
    required this.createdAt,
  });

  final int? id;
  final int purchaseBillId, sizeBytes;
  final String fileName, localPath;
  final String? mimeType;
  final DateTime createdAt;
}

class SupplierStatementEntry {
  const SupplierStatementEntry({
    required this.date,
    required this.title,
    required this.reference,
    required this.debitMinor,
    required this.creditMinor,
    required this.balanceMinor,
    required this.type,
  });
  final DateTime date;
  final String title, reference, type;
  final int debitMinor, creditMinor, balanceMinor;
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
