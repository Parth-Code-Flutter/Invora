import 'dart:async';

import 'package:get/get.dart';

import '../../../app/enums/item_type.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../data/models/product_service_model.dart';
import '../../../data/models/stock_models.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/services/stock_ledger.dart';

class StockController extends GetxController {
  StockController(this._ledger, this._products);

  final StockLedger _ledger;
  final ProductRepository _products;
  final movements = <StockMovementModel>[].obs;
  final products = <ProductServiceModel>[].obs;
  final namesById = <int, String>{}.obs;
  final isLoading = true.obs;
  StreamSubscription<List<StockMovementModel>>? _subscription;
  StreamSubscription<List<ProductServiceModel>>? _catalogSubscription;

  Map<int, String> get productNames => namesById;

  List<ProductServiceModel> get trackedProducts => products
      .where(
        (item) =>
            item.trackStock && item.type == ItemType.product && item.id != null,
      )
      .toList(growable: false);

  @override
  void onInit() {
    super.onInit();
    _catalogSubscription = _products.watchItems(type: ItemType.product).listen((
      rows,
    ) {
      products.assignAll(rows);
      namesById.assignAll({
        for (final row in rows)
          if (row.id != null) row.id!: row.name,
      });
    });
    _subscription = _ledger.watchRecent().listen((rows) {
      movements.assignAll(rows);
      isLoading.value = false;
    });
  }

  Future<void> adjust({
    required int productId,
    required int quantityScaled,
    required String reason,
  }) async {
    try {
      await _ledger.adjust(
        productId: productId,
        quantityScaled: quantityScaled,
        reason: reason,
      );
      AppNotification.success(
        'Stock adjusted',
        'The movement is saved. On-hand is updated from the ledger.',
      );
    } catch (error) {
      AppNotification.error(
        'Could not adjust stock',
        error is ArgumentError || error is StateError
            ? error.toString().replaceFirst(RegExp(r'^[^:]+:\s*'), '')
            : 'Enter a quantity and a reason, then try again.',
      );
      rethrow;
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _catalogSubscription?.cancel();
    super.onClose();
  }
}
