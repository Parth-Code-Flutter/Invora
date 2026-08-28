import 'purchase_models.dart';

enum PurchaseOrderStatus {
  draft,
  open,
  partReceived,
  received,
  partBilled,
  billed,
  cancelled,
}

class PurchaseOrderEditorArgs {
  const PurchaseOrderEditorArgs({this.orderId, this.supplierId});

  final int? orderId;
  final int? supplierId;
}

class PurchaseOrderItemModel {
  const PurchaseOrderItemModel({
    required this.localId,
    this.id,
    this.productId,
    required this.name,
    this.description,
    required this.orderedQuantityScaled,
    this.receivedQuantityScaled = 0,
    this.returnedQuantityScaled = 0,
    this.billedQuantityScaled = 0,
    required this.unit,
    required this.rateMinor,
    this.hsnSac,
    this.taxRateBasisPoints = 0,
  });

  final String localId;
  final int? id;
  final int? productId;
  final String name;
  final String? description;
  final int orderedQuantityScaled;
  final int receivedQuantityScaled;
  final int returnedQuantityScaled;
  final int billedQuantityScaled;
  final String unit;
  final int rateMinor;
  final String? hsnSac;
  final int taxRateBasisPoints;

  int get remainingToReceiveScaled {
    final remaining = orderedQuantityScaled - receivedQuantityScaled;
    return remaining < 0 ? 0 : remaining;
  }

  int get remainingToBillScaled {
    final remaining =
        receivedQuantityScaled - returnedQuantityScaled - billedQuantityScaled;
    return remaining < 0 ? 0 : remaining;
  }

  PurchaseOrderItemModel copyWith({
    int? orderedQuantityScaled,
    int? receivedQuantityScaled,
    int? returnedQuantityScaled,
    int? billedQuantityScaled,
  }) {
    return PurchaseOrderItemModel(
      localId: localId,
      id: id,
      productId: productId,
      name: name,
      description: description,
      orderedQuantityScaled:
          orderedQuantityScaled ?? this.orderedQuantityScaled,
      receivedQuantityScaled:
          receivedQuantityScaled ?? this.receivedQuantityScaled,
      returnedQuantityScaled:
          returnedQuantityScaled ?? this.returnedQuantityScaled,
      billedQuantityScaled: billedQuantityScaled ?? this.billedQuantityScaled,
      unit: unit,
      rateMinor: rateMinor,
      hsnSac: hsnSac,
      taxRateBasisPoints: taxRateBasisPoints,
    );
  }
}

class PurchaseOrderConversionModel {
  const PurchaseOrderConversionModel({
    required this.purchaseBillId,
    required this.billNumber,
    required this.convertedAt,
  });

  final int purchaseBillId;
  final String billNumber;
  final DateTime convertedAt;
}

class PurchaseOrderSummaryModel {
  const PurchaseOrderSummaryModel({
    required this.id,
    required this.orderNumber,
    required this.supplierName,
    required this.orderDate,
    required this.status,
    required this.itemCount,
  });

  final int id;
  final String orderNumber;
  final String supplierName;
  final DateTime orderDate;
  final PurchaseOrderStatus status;
  final int itemCount;
}

class PurchaseOrderModel {
  const PurchaseOrderModel({
    this.id,
    required this.orderNumber,
    required this.supplier,
    required this.orderDate,
    this.expectedDate,
    required this.status,
    this.taxMode = 'cgst_sgst',
    this.terms,
    this.notes,
    this.cancellationReason,
    this.cancelledAt,
    required this.items,
    this.conversions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String orderNumber;
  final SupplierModel supplier;
  final DateTime orderDate;
  final DateTime? expectedDate;
  final PurchaseOrderStatus status;
  final String taxMode;
  final String? terms;
  final String? notes;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final List<PurchaseOrderItemModel> items;
  final List<PurchaseOrderConversionModel> conversions;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCancelled => status == PurchaseOrderStatus.cancelled;
  bool get isDraft => status == PurchaseOrderStatus.draft;
  bool get canConvert =>
      !isCancelled && items.any((item) => item.remainingToBillScaled > 0);
  bool get canEdit =>
      !isCancelled && items.every((item) => item.billedQuantityScaled == 0);
  bool get canCancel =>
      !isCancelled && items.every((item) => item.billedQuantityScaled == 0);
  bool get canReceive =>
      !isCancelled && items.any((item) => item.orderedQuantityScaled > 0);

  int get remainingToBillScaled =>
      items.fold<int>(0, (total, item) => total + item.remainingToBillScaled);
}

abstract final class PurchaseOrderLabels {
  static String status(PurchaseOrderStatus value) => switch (value) {
    PurchaseOrderStatus.draft => 'Draft',
    PurchaseOrderStatus.open => 'Open',
    PurchaseOrderStatus.partReceived => 'Part received',
    PurchaseOrderStatus.received => 'Received',
    PurchaseOrderStatus.partBilled => 'Part billed',
    PurchaseOrderStatus.billed => 'Billed',
    PurchaseOrderStatus.cancelled => 'Cancelled',
  };
}
