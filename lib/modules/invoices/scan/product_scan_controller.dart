import 'package:get/get.dart';

import '../../../data/models/product_service_model.dart';
import '../../../data/models/scanned_invoice_line.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/services/barcode_catalog_lookup.dart';
import 'product_scan_session.dart';

/// GetX wrapper around [ProductScanSession] for the live scanner screen.
class ProductScanController extends GetxController {
  ProductScanController(this._products, this._business);

  final ProductRepository _products;
  final BusinessRepository _business;
  late final BarcodeCatalogLookup _lookup = BarcodeCatalogLookup(_products);
  final ProductScanSession session = ProductScanSession();

  final lines = <ScannedInvoiceLine>[].obs;
  final currencySymbol = '₹'.obs;
  final isBusy = false.obs;

  int get uniqueItemCount => session.uniqueItemCount;
  int get totalMinor => session.totalMinor;

  @override
  void onInit() {
    super.onInit();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final profile = await _business.getProfile();
    currencySymbol.value = profile?.currencySymbol ?? '₹';
  }

  Future<ProductServiceModel?> lookup(String rawCode) {
    return _lookup.find(rawCode);
  }

  ScanApplyResult acceptProduct({
    required ProductServiceModel product,
    required String rawCode,
  }) {
    final result = session.applyProduct(product: product, rawCode: rawCode);
    _syncLines();
    return result;
  }

  void incrementAt(int index) {
    session.incrementAt(index);
    _syncLines();
  }

  void decrementAt(int index) {
    session.decrementAt(index);
    _syncLines();
  }

  void _syncLines() => lines.assignAll(session.lines);
}
