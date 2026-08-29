import '../../app/utils/quantity_utils.dart';
import 'gst_export_model.dart';
import 'stock_models.dart';

enum StockReportKind { onHand, movements }

class StockOnHandRow {
  const StockOnHandRow({
    required this.productId,
    required this.name,
    required this.unit,
    required this.quantityScaled,
  });

  final int productId;
  final String name;
  final String unit;
  final int quantityScaled;

  String get quantityLabel => QuantityUtils.formatSigned(quantityScaled);
}

class StockMovementReportRow {
  const StockMovementReportRow({
    required this.movement,
    required this.productName,
    required this.unit,
  });

  final StockMovementModel movement;
  final String productName;
  final String unit;

  StockMovementType get type => StockMovementType.fromStorage(movement.type);

  StockSourceType get source =>
      StockSourceType.fromStorage(movement.sourceType);

  String get quantityLabel =>
      QuantityUtils.formatSigned(movement.quantityScaled);
}

class StockReportPack {
  const StockReportPack({
    required this.kind,
    required this.enabled,
    required this.asOf,
    required this.period,
    required this.onHand,
    required this.movements,
  });

  final StockReportKind kind;
  final bool enabled;
  final DateTime asOf;
  final GstExportPeriod period;
  final List<StockOnHandRow> onHand;
  final List<StockMovementReportRow> movements;

  int get productCount => onHand.length;

  int get negativeCount => onHand.where((row) => row.quantityScaled < 0).length;

  int get inScaled => movements.fold<int>(
    0,
    (sum, row) => row.movement.quantityScaled > 0
        ? sum + row.movement.quantityScaled
        : sum,
  );

  int get outScaled => movements.fold<int>(
    0,
    (sum, row) => row.movement.quantityScaled < 0
        ? sum + row.movement.quantityScaled.abs()
        : sum,
  );

  String get rangeLabel => kind == StockReportKind.onHand
      ? StockDay.display(asOf)
      : period.rangeLabel;
}
