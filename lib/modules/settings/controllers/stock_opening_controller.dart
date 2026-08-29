import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/enums/item_type.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../data/models/product_service_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/services/stock_ledger.dart';

class StockOpeningController extends GetxController {
  StockOpeningController(this._ledger, this._products);

  final StockLedger _ledger;
  final ProductRepository _products;
  final products = <ProductServiceModel>[].obs;
  final qtyByProduct = <int, TextEditingController>{};
  final openingAsOf = DateTime.now().obs;
  final isSaving = false.obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    final rows = await _products.watchItems(type: ItemType.product).first;
    products.assignAll(rows);
    for (final product in rows) {
      final id = product.id;
      if (id == null) continue;
      qtyByProduct[id] = TextEditingController();
    }
    isLoading.value = false;
  }

  Future<void> save() async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      final qty = <int, int>{};
      for (final product in products) {
        final id = product.id;
        if (id == null) continue;
        final raw = qtyByProduct[id]?.text ?? '';
        if (raw.trim().isEmpty) {
          qty[id] = 0;
          continue;
        }
        final parsed = QuantityUtils.parseScaled(raw);
        if (parsed == null) {
          AppNotification.error(
            'Check quantities',
            'Use whole numbers or up to three decimals. Leave blank for zero.',
          );
          return;
        }
        qty[id] = parsed;
      }
      await _ledger.enable(
        openingAsOf: DateTime(
          openingAsOf.value.year,
          openingAsOf.value.month,
          openingAsOf.value.day,
        ),
        openingQtyByProduct: qty,
      );
      Get.back<void>();
      AppNotification.success(
        'Stock tracking on',
        'Opening quantities are saved. Invoices and bills will move stock.',
      );
    } catch (_) {
      AppNotification.error(
        'Could not turn on stock',
        'Please try again. Existing catalog items were not changed.',
      );
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    for (final controller in qtyByProduct.values) {
      controller.dispose();
    }
    super.onClose();
  }
}
