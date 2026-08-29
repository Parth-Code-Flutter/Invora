import '../services/app_database.dart';

enum StockMovementType {
  opening,
  sale,
  saleReversal,
  purchase,
  purchaseReversal,
  creditNote,
  debitNote,
  adjustment,
  reversal;

  String get storage => switch (this) {
    StockMovementType.opening => 'opening',
    StockMovementType.sale => 'sale',
    StockMovementType.saleReversal => 'sale_reversal',
    StockMovementType.purchase => 'purchase',
    StockMovementType.purchaseReversal => 'purchase_reversal',
    StockMovementType.creditNote => 'credit_note',
    StockMovementType.debitNote => 'debit_note',
    StockMovementType.adjustment => 'adjustment',
    StockMovementType.reversal => 'reversal',
  };

  int signedQuantity(int quantityScaled) => switch (this) {
    StockMovementType.sale || StockMovementType.debitNote => -quantityScaled,
    _ => quantityScaled,
  };

  String get label => switch (this) {
    StockMovementType.opening => 'Opening',
    StockMovementType.sale => 'Sale',
    StockMovementType.saleReversal => 'Sale reversed',
    StockMovementType.purchase => 'Purchase',
    StockMovementType.purchaseReversal => 'Purchase reversed',
    StockMovementType.creditNote => 'Credit note',
    StockMovementType.debitNote => 'Debit note',
    StockMovementType.adjustment => 'Adjustment',
    StockMovementType.reversal => 'Reversal',
  };

  static StockMovementType fromStorage(String value) {
    return StockMovementType.values.firstWhere(
      (type) => type.storage == value,
      orElse: () => StockMovementType.reversal,
    );
  }
}

abstract final class StockMovementTypeX {
  static String reversalOf(String type) => switch (type) {
    'sale' => StockMovementType.saleReversal.storage,
    'purchase' => StockMovementType.purchaseReversal.storage,
    _ => StockMovementType.reversal.storage,
  };
}

enum StockSourceType {
  invoice,
  purchaseBill,
  creditNote,
  debitNote,
  opening,
  adjustment;

  String get storage => switch (this) {
    StockSourceType.invoice => 'invoice',
    StockSourceType.purchaseBill => 'purchase_bill',
    StockSourceType.creditNote => 'credit_note',
    StockSourceType.debitNote => 'debit_note',
    StockSourceType.opening => 'opening',
    StockSourceType.adjustment => 'adjustment',
  };

  String get label => switch (this) {
    StockSourceType.invoice => 'Invoice',
    StockSourceType.purchaseBill => 'Purchase bill',
    StockSourceType.creditNote => 'Credit note',
    StockSourceType.debitNote => 'Debit note',
    StockSourceType.opening => 'Opening',
    StockSourceType.adjustment => 'Adjustment',
  };

  static StockSourceType fromStorage(String value) {
    return StockSourceType.values.firstWhere(
      (type) => type.storage == value,
      orElse: () => StockSourceType.adjustment,
    );
  }
}

/// Calendar-day bounds for stock as-of and movement-range reports.
abstract final class StockDay {
  static DateTime start(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime end(DateTime value) =>
      DateTime(value.year, value.month, value.day, 23, 59, 59, 999);

  static String iso(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static String display(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  static String displayDateTime(DateTime value) =>
      '${display(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class StockLine {
  const StockLine({required this.productId, required this.quantityScaled});

  final int productId;
  final int quantityScaled;
}

class StockSettingsData {
  const StockSettingsData({
    required this.enabled,
    this.enabledAt,
    this.openingAsOf,
  });

  final bool enabled;
  final DateTime? enabledAt;
  final DateTime? openingAsOf;

  factory StockSettingsData.fromRow(StockSetting row) => StockSettingsData(
    enabled: row.enabled,
    enabledAt: row.enabledAt,
    openingAsOf: row.openingAsOf,
  );
}

class StockMovementModel {
  const StockMovementModel({
    required this.id,
    required this.productId,
    required this.quantityScaled,
    required this.type,
    this.reason,
    required this.sourceType,
    this.sourceId,
    this.reversesMovementId,
    required this.createdAt,
  });

  final int id;
  final int productId;
  final int quantityScaled;
  final String type;
  final String? reason;
  final String sourceType;
  final int? sourceId;
  final int? reversesMovementId;
  final DateTime createdAt;

  factory StockMovementModel.fromRow(StockMovement row) => StockMovementModel(
    id: row.id,
    productId: row.productId,
    quantityScaled: row.quantityScaled,
    type: row.type,
    reason: row.reason,
    sourceType: row.sourceType,
    sourceId: row.sourceId,
    reversesMovementId: row.reversesMovementId,
    createdAt: row.createdAt,
  );
}
