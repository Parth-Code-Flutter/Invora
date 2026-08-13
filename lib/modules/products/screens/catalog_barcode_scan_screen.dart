import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/widgets/app_dialog.dart';
import '../../../app/widgets/barcode_scanner_scaffold.dart';
import '../../../data/models/product_form_args.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/services/barcode_catalog_lookup.dart';

/// Full-screen scanner for creating or opening a catalog product from a barcode.
class CatalogBarcodeScanScreen extends StatefulWidget {
  const CatalogBarcodeScanScreen({super.key});

  @override
  State<CatalogBarcodeScanScreen> createState() =>
      _CatalogBarcodeScanScreenState();
}

class _CatalogBarcodeScanScreenState extends State<CatalogBarcodeScanScreen> {
  final _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 800,
    facing: CameraFacing.back,
  );
  late final BarcodeCatalogLookup _lookup;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _lookup = BarcodeCatalogLookup(Get.find<ProductRepository>());
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final code = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .map((value) => value.trim())
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (code.isEmpty) return;
    _busy = true;
    try {
      await _scanner.pause();
      HapticFeedback.selectionClick();
      final product = await _lookup.find(code);
      if (!mounted) return;
      if (product != null) {
        await Get.offNamed<void>(
          AppRoutes.productDetails,
          arguments: product.id,
        );
        return;
      }
      final save = await showAppConfirmDialog(
        context: context,
        icon: Icons.inventory_2_outlined,
        tone: AppDialogTone.info,
        title: 'Save this barcode?',
        message:
            'No saved product uses $code. Create a catalog item with this SKU.',
        confirmLabel: 'Create product',
        cancelLabel: 'Keep scanning',
      );
      if (!mounted) return;
      if (save) {
        await Get.offNamed<void>(
          AppRoutes.productAdd,
          arguments: ProductFormArgs(initialSku: code),
        );
        return;
      }
      await _scanner.start();
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BarcodeScannerScaffold(
      controller: _scanner,
      onDetect: _onDetect,
      title: 'Scan product',
      hint: 'Align the barcode inside the frame to open or create a product.',
    );
  }
}
