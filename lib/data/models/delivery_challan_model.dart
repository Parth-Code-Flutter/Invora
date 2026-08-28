import 'invoice_model.dart';

enum DeliveryChallanStatus {
  draft,
  open,
  partDelivered,
  delivered,
  partInvoiced,
  invoiced,
  cancelled,
}

enum DeliveryChallanSourceType { blank, quotation, invoice }

enum MovementReason { supply, jobWork, ownUse, exhibition, other }

enum EwayStatus { none, prepared, generated }

class DeliveryChallanEditorArgs {
  const DeliveryChallanEditorArgs({
    this.challanId,
    this.customerId,
    this.quotationId,
    this.invoiceId,
  });

  final int? challanId;
  final int? customerId;
  final int? quotationId;
  final int? invoiceId;
}

class DeliveryChallanItemModel {
  const DeliveryChallanItemModel({
    required this.localId,
    this.id,
    this.productId,
    this.sourceItemId,
    required this.name,
    this.description,
    required this.orderedQuantityScaled,
    required this.dispatchedQuantityScaled,
    this.deliveredQuantityScaled = 0,
    this.returnedQuantityScaled = 0,
    this.invoicedQuantityScaled = 0,
    required this.unit,
    required this.rateMinor,
    this.hsnSac,
    this.taxRateBasisPoints = 0,
  });

  final String localId;
  final int? id;
  final int? productId;
  final int? sourceItemId;
  final String name;
  final String? description;
  final int orderedQuantityScaled;
  final int dispatchedQuantityScaled;
  final int deliveredQuantityScaled;
  final int returnedQuantityScaled;
  final int invoicedQuantityScaled;
  final String unit;
  final int rateMinor;
  final String? hsnSac;
  final int taxRateBasisPoints;

  int get remainingToInvoiceScaled {
    final remaining =
        dispatchedQuantityScaled -
        returnedQuantityScaled -
        invoicedQuantityScaled;
    return remaining < 0 ? 0 : remaining;
  }

  DeliveryChallanItemModel copyWith({
    int? orderedQuantityScaled,
    int? dispatchedQuantityScaled,
    int? deliveredQuantityScaled,
    int? returnedQuantityScaled,
    int? invoicedQuantityScaled,
  }) {
    return DeliveryChallanItemModel(
      localId: localId,
      id: id,
      productId: productId,
      sourceItemId: sourceItemId,
      name: name,
      description: description,
      orderedQuantityScaled:
          orderedQuantityScaled ?? this.orderedQuantityScaled,
      dispatchedQuantityScaled:
          dispatchedQuantityScaled ?? this.dispatchedQuantityScaled,
      deliveredQuantityScaled:
          deliveredQuantityScaled ?? this.deliveredQuantityScaled,
      returnedQuantityScaled:
          returnedQuantityScaled ?? this.returnedQuantityScaled,
      invoicedQuantityScaled:
          invoicedQuantityScaled ?? this.invoicedQuantityScaled,
      unit: unit,
      rateMinor: rateMinor,
      hsnSac: hsnSac,
      taxRateBasisPoints: taxRateBasisPoints,
    );
  }
}

class DeliveryChallanConversionModel {
  const DeliveryChallanConversionModel({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.convertedAt,
  });

  final int invoiceId;
  final String invoiceNumber;
  final DateTime convertedAt;
}

class DeliveryChallanSummaryModel {
  const DeliveryChallanSummaryModel({
    required this.id,
    required this.challanNumber,
    required this.customerName,
    required this.challanDate,
    required this.status,
    required this.movementReason,
    required this.itemCount,
  });

  final int id;
  final String challanNumber;
  final String customerName;
  final DateTime challanDate;
  final DeliveryChallanStatus status;
  final MovementReason movementReason;
  final int itemCount;
}

class DeliveryChallanModel {
  const DeliveryChallanModel({
    this.id,
    required this.challanNumber,
    required this.customer,
    this.sourceType = DeliveryChallanSourceType.blank,
    this.sourceId,
    this.sourceNumber,
    required this.challanDate,
    this.dispatchDate,
    required this.status,
    required this.movementReason,
    this.movementReasonNote,
    this.dispatchAddress,
    this.dispatchCity,
    this.dispatchState,
    this.dispatchPinCode,
    this.deliveryAddress,
    this.deliveryCity,
    this.deliveryState,
    this.deliveryPinCode,
    this.transporterName,
    this.transporterId,
    this.vehicleNumber,
    this.transportDocumentNumber,
    this.transportDocumentDate,
    this.distanceKm,
    this.ewayStatus = EwayStatus.none,
    this.ewayNumber,
    this.notes,
    this.cancellationReason,
    this.cancelledAt,
    required this.items,
    this.conversions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String challanNumber;
  final CustomerSnapshotModel customer;
  final DeliveryChallanSourceType sourceType;
  final int? sourceId;
  final String? sourceNumber;
  final DateTime challanDate;
  final DateTime? dispatchDate;
  final DeliveryChallanStatus status;
  final MovementReason movementReason;
  final String? movementReasonNote;
  final String? dispatchAddress;
  final String? dispatchCity;
  final String? dispatchState;
  final String? dispatchPinCode;
  final String? deliveryAddress;
  final String? deliveryCity;
  final String? deliveryState;
  final String? deliveryPinCode;
  final String? transporterName;
  final String? transporterId;
  final String? vehicleNumber;
  final String? transportDocumentNumber;
  final DateTime? transportDocumentDate;
  final int? distanceKm;
  final EwayStatus ewayStatus;
  final String? ewayNumber;
  final String? notes;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final List<DeliveryChallanItemModel> items;
  final List<DeliveryChallanConversionModel> conversions;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCancelled => status == DeliveryChallanStatus.cancelled;
  bool get isDraft => status == DeliveryChallanStatus.draft;
  bool get isAgainstInvoice => sourceType == DeliveryChallanSourceType.invoice;
  bool get isFromQuotation => sourceType == DeliveryChallanSourceType.quotation;
  bool get canConvert =>
      !isCancelled &&
      !isAgainstInvoice &&
      movementReason == MovementReason.supply &&
      items.any((item) => item.remainingToInvoiceScaled > 0);
  bool get canEdit =>
      !isCancelled && items.every((item) => item.invoicedQuantityScaled == 0);
  bool get canCancel =>
      !isCancelled && items.every((item) => item.invoicedQuantityScaled == 0);
  bool get hasTransportDetails {
    final transporter = transporterName?.trim() ?? '';
    final vehicle = vehicleNumber?.trim() ?? '';
    return transporter.isNotEmpty || vehicle.isNotEmpty;
  }

  String? get sourceCaption =>
      DeliveryChallanLabels.source(sourceType, sourceNumber);

  int get remainingToInvoiceScaled => items.fold<int>(
    0,
    (total, item) => total + item.remainingToInvoiceScaled,
  );
}

abstract final class DeliveryChallanLabels {
  static String status(DeliveryChallanStatus value) => switch (value) {
    DeliveryChallanStatus.draft => 'Draft',
    DeliveryChallanStatus.open => 'Open',
    DeliveryChallanStatus.partDelivered => 'Part delivered',
    DeliveryChallanStatus.delivered => 'Delivered',
    DeliveryChallanStatus.partInvoiced => 'Part invoiced',
    DeliveryChallanStatus.invoiced => 'Invoiced',
    DeliveryChallanStatus.cancelled => 'Cancelled',
  };

  static String reason(MovementReason value) => switch (value) {
    MovementReason.supply => 'Supply (sale)',
    MovementReason.jobWork => 'Job work',
    MovementReason.ownUse => 'Own use',
    MovementReason.exhibition => 'Exhibition',
    MovementReason.other => 'Other',
  };

  static String eway(EwayStatus value) => switch (value) {
    EwayStatus.none => 'E-way: Not prepared',
    EwayStatus.prepared => 'E-way: Prepared',
    EwayStatus.generated => 'E-way bill (imported)',
  };

  static String? source(DeliveryChallanSourceType type, String? number) {
    final value = number?.trim() ?? '';
    if (value.isEmpty) return null;
    return switch (type) {
      DeliveryChallanSourceType.quotation => 'From quotation $value',
      DeliveryChallanSourceType.invoice => 'Against invoice $value',
      DeliveryChallanSourceType.blank => null,
    };
  }
}
