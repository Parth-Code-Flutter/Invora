import 'package:drift/drift.dart';

import '../../app/enums/item_type.dart';
import '../models/stock_models.dart';
import 'app_database.dart';

/// Immutable product-stock postings. Quantities are never updated in place.
class StockLedger {
  const StockLedger(this.database);

  final AppDatabase database;

  /// True when at least one live catalog product has Keep stock on.
  Future<bool> isEnabled() async {
    final row =
        await (database.select(database.productServices)
              ..where(
                (table) =>
                    table.trackStock.equals(true) &
                    table.type.equals(ItemType.product.name) &
                    table.isDeleted.equals(false),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  Future<StockSettingsData?> settings() async {
    final row = await _settings();
    return row == null ? null : StockSettingsData.fromRow(row);
  }

  Future<int> onHand(int productId) async {
    final map = await onHandByProduct({productId});
    return map[productId] ?? 0;
  }

  Future<Map<int, int>> onHandByProduct(Iterable<int> productIds) async {
    final ids = productIds.toSet();
    if (ids.isEmpty) return const {};
    final rows = await (database.select(
      database.stockMovements,
    )..where((table) => table.productId.isIn(ids))).get();
    final totals = <int, int>{for (final id in ids) id: 0};
    for (final row in rows) {
      totals[row.productId] = (totals[row.productId] ?? 0) + row.quantityScaled;
    }
    return totals;
  }

  /// On-hand at the end of [asOf]'s calendar day, using movement `createdAt`.
  Future<Map<int, int>> onHandAsOf(
    DateTime asOf, {
    Iterable<int>? productIds,
  }) async {
    final ids = productIds?.toSet();
    if (ids != null && ids.isEmpty) return const {};
    final end = StockDay.end(asOf);
    final statement = database.select(database.stockMovements)
      ..where((table) => table.createdAt.isSmallerOrEqualValue(end));
    if (ids != null) {
      statement.where((table) => table.productId.isIn(ids));
    }
    final rows = await statement.get();
    final totals = <int, int>{
      if (ids != null)
        for (final id in ids) id: 0,
    };
    for (final row in rows) {
      totals[row.productId] = (totals[row.productId] ?? 0) + row.quantityScaled;
    }
    return totals;
  }

  Future<List<StockMovementModel>> movementsInRange({
    required DateTime from,
    required DateTime to,
  }) async {
    final start = StockDay.start(from);
    final end = StockDay.end(to);
    final rows =
        await (database.select(database.stockMovements)
              ..where(
                (table) =>
                    table.createdAt.isBiggerOrEqualValue(start) &
                    table.createdAt.isSmallerOrEqualValue(end),
              )
              ..orderBy([
                (table) => OrderingTerm.asc(table.createdAt),
                (table) => OrderingTerm.asc(table.id),
              ]))
            .get();
    return rows.map(StockMovementModel.fromRow).toList(growable: false);
  }

  Stream<bool> watchEnabled() {
    return (database.select(database.productServices)..where(
          (table) =>
              table.trackStock.equals(true) &
              table.type.equals(ItemType.product.name) &
              table.isDeleted.equals(false),
        ))
        .watch()
        .map((rows) => rows.isNotEmpty);
  }

  Stream<List<StockMovementModel>> watchRecent({int limit = 200}) {
    final statement = database.select(database.stockMovements)
      ..orderBy([(table) => OrderingTerm.desc(table.id)])
      ..limit(limit);
    return statement.watch().map(
      (rows) => rows.map(StockMovementModel.fromRow).toList(growable: false),
    );
  }

  Future<bool> hasMovements(int productId) async {
    final row =
        await (database.select(database.stockMovements)
              ..where((table) => table.productId.equals(productId))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  /// Turns Keep stock on or off for one catalog product.
  ///
  /// Opening quantity posts only the first time this product has no movements.
  Future<void> setProductTracked({
    required int productId,
    required bool tracked,
    int openingQtyScaled = 0,
  }) async {
    await (database.update(
      database.productServices,
    )..where((table) => table.id.equals(productId))).write(
      ProductServicesCompanion(
        trackStock: Value(tracked),
        updatedAt: Value(DateTime.now()),
      ),
    );
    if (!tracked || openingQtyScaled <= 0) return;
    if (await hasMovements(productId)) return;
    final trackedIds = await _trackedProductIds({productId});
    if (!trackedIds.contains(productId)) return;
    await _insert(
      productId: productId,
      quantityScaled: openingQtyScaled,
      type: StockMovementType.opening,
      sourceType: StockSourceType.opening,
      sourceId: productId,
      createdAt: DateTime.now(),
    );
  }

  /// Sets Keep stock and aligns on-hand to [quantityScaled].
  ///
  /// Null quantity leaves existing on-hand unchanged. First count posts
  /// opening (blank treated as zero). Later edits post an adjustment.
  Future<void> applyCatalogQuantity({
    required int productId,
    required bool tracked,
    int? quantityScaled,
  }) async {
    await (database.update(
      database.productServices,
    )..where((table) => table.id.equals(productId))).write(
      ProductServicesCompanion(
        trackStock: Value(tracked),
        updatedAt: Value(DateTime.now()),
      ),
    );
    if (!tracked) return;
    final alreadyPosted = await hasMovements(productId);
    if (!alreadyPosted) {
      final qty = quantityScaled ?? 0;
      if (qty <= 0) return;
      await _insert(
        productId: productId,
        quantityScaled: qty,
        type: StockMovementType.opening,
        sourceType: StockSourceType.opening,
        sourceId: productId,
        createdAt: DateTime.now(),
      );
      return;
    }
    if (quantityScaled == null) return;
    final current = await onHand(productId);
    final delta = quantityScaled - current;
    if (delta == 0) return;
    await _insert(
      productId: productId,
      quantityScaled: delta,
      type: StockMovementType.adjustment,
      reason: 'Catalog quantity',
      sourceType: StockSourceType.adjustment,
      createdAt: DateTime.now(),
    );
  }

  Future<void> enable({
    required DateTime openingAsOf,
    required Map<int, int> openingQtyByProduct,
  }) async {
    await database.transaction(() async {
      final now = DateTime.now();
      for (final productId in openingQtyByProduct.keys) {
        await (database.update(
          database.productServices,
        )..where((table) => table.id.equals(productId))).write(
          ProductServicesCompanion(
            trackStock: const Value(true),
            updatedAt: Value(now),
          ),
        );
      }
      await (database.update(
        database.stockSettings,
      )..where((table) => table.id.equals(1))).write(
        StockSettingsCompanion(
          enabled: const Value(true),
          enabledAt: Value(now),
          openingAsOf: Value(openingAsOf),
        ),
      );
      final tracked = await _trackedProductIds(openingQtyByProduct.keys);
      for (final productId in tracked) {
        final qty = openingQtyByProduct[productId] ?? 0;
        if (qty == 0) continue;
        if (await hasMovements(productId)) continue;
        await _insert(
          productId: productId,
          quantityScaled: qty,
          type: StockMovementType.opening,
          sourceType: StockSourceType.opening,
          sourceId: productId,
          createdAt: now,
        );
      }
    });
  }

  Future<void> disable() async {
    await database.transaction(() async {
      await (database.update(
        database.productServices,
      )..where((table) => table.trackStock.equals(true))).write(
        ProductServicesCompanion(
          trackStock: const Value(false),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await (database.update(database.stockSettings)
            ..where((table) => table.id.equals(1)))
          .write(const StockSettingsCompanion(enabled: Value(false)));
    });
  }

  Future<void> replaceSource({
    required StockSourceType sourceType,
    required int sourceId,
    required StockMovementType type,
    required List<StockLine> lines,
  }) async {
    if (!await isEnabled()) return;
    await reverseSource(sourceType: sourceType, sourceId: sourceId);
    if (type == StockMovementType.saleReversal ||
        type == StockMovementType.purchaseReversal) {
      return;
    }
    final tracked = await _trackedProductIds(
      lines.map((line) => line.productId),
    );
    final now = DateTime.now();
    for (final line in lines) {
      if (line.quantityScaled <= 0 || !tracked.contains(line.productId)) {
        continue;
      }
      await _insert(
        productId: line.productId,
        quantityScaled: type.signedQuantity(line.quantityScaled),
        type: type,
        sourceType: sourceType,
        sourceId: sourceId,
        createdAt: now,
      );
    }
  }

  Future<void> reverseSource({
    required StockSourceType sourceType,
    required int sourceId,
  }) async {
    if (!await isEnabled()) return;
    final active = await _activeForSource(
      sourceType: sourceType,
      sourceId: sourceId,
    );
    final now = DateTime.now();
    for (final row in active) {
      await _insert(
        productId: row.productId,
        quantityScaled: -row.quantityScaled,
        type: StockMovementType.fromStorage(
          StockMovementTypeX.reversalOf(row.type),
        ),
        sourceType: sourceType,
        sourceId: sourceId,
        reversesMovementId: row.id,
        createdAt: now,
      );
    }
  }

  Future<void> adjust({
    required int productId,
    required int quantityScaled,
    required String reason,
  }) async {
    final normalized = reason.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('An adjustment reason is required.');
    }
    if (quantityScaled == 0) {
      throw ArgumentError('Adjustment quantity cannot be zero.');
    }
    final tracked = await _trackedProductIds({productId});
    if (!tracked.contains(productId)) {
      throw StateError('Keep stock for this item is off.');
    }
    await _insert(
      productId: productId,
      quantityScaled: quantityScaled,
      type: StockMovementType.adjustment,
      reason: normalized,
      sourceType: StockSourceType.adjustment,
      createdAt: DateTime.now(),
    );
  }

  Future<StockSetting?> _settings() {
    return (database.select(
      database.stockSettings,
    )..where((table) => table.id.equals(1))).getSingleOrNull();
  }

  Future<List<StockMovement>> _activeForSource({
    required StockSourceType sourceType,
    required int sourceId,
  }) async {
    final rows =
        await (database.select(database.stockMovements)..where(
              (table) =>
                  table.sourceType.equals(sourceType.storage) &
                  table.sourceId.equals(sourceId),
            ))
            .get();
    final reversed = rows
        .where((row) => row.reversesMovementId != null)
        .map((row) => row.reversesMovementId!)
        .toSet();
    return rows
        .where(
          (row) => row.reversesMovementId == null && !reversed.contains(row.id),
        )
        .toList(growable: false);
  }

  Future<Set<int>> _trackedProductIds(Iterable<int> ids) async {
    final unique = ids.toSet();
    if (unique.isEmpty) return const {};
    final rows =
        await (database.select(database.productServices)..where(
              (table) =>
                  table.id.isIn(unique) &
                  table.trackStock.equals(true) &
                  table.type.equals(ItemType.product.name) &
                  table.isDeleted.equals(false),
            ))
            .get();
    return rows.map((row) => row.id).toSet();
  }

  Future<void> _insert({
    required int productId,
    required int quantityScaled,
    required StockMovementType type,
    required StockSourceType sourceType,
    required DateTime createdAt,
    int? sourceId,
    int? reversesMovementId,
    String? reason,
  }) async {
    await database
        .into(database.stockMovements)
        .insert(
          StockMovementsCompanion.insert(
            productId: productId,
            quantityScaled: quantityScaled,
            type: type.storage,
            reason: Value(reason),
            sourceType: sourceType.storage,
            sourceId: Value(sourceId),
            reversesMovementId: Value(reversesMovementId),
            createdAt: Value(createdAt),
          ),
        );
  }
}
