import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/routes/app_routes.dart';
import '../../app/widgets/barcode_scanner_scaffold.dart';
import '../../data/models/barcode_capture_result.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/services/barcode_catalog_lookup.dart';

/// Captures a single barcode, looks it up offline, and pops the result.
///
/// Used by forms that want to fill fields and let the user edit before saving.
class BarcodeCaptureScreen extends StatefulWidget {
  const BarcodeCaptureScreen({super.key});

  /// Opens capture and returns the decoded value for list search.
  static Future<String?> captureQuery() async {
    final result = await Get.toNamed<dynamic>(
      AppRoutes.barcodeCapture,
      arguments: 'Align the barcode inside the frame to search.',
    );
    if (result is! BarcodeCaptureResult) return null;
    final code = result.code.trim();
    return code.isEmpty ? null : code;
  }

  @override
  State<BarcodeCaptureScreen> createState() => _BarcodeCaptureScreenState();
}

class _BarcodeCaptureScreenState extends State<BarcodeCaptureScreen> {
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
      Get.back(
        result: BarcodeCaptureResult(code: code, product: product),
      );
    } catch (_) {
      _busy = false;
      await _scanner.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BarcodeScannerScaffold(
      controller: _scanner,
      onDetect: _onDetect,
      title: 'Scan barcode',
      hint: _hint,
    );
  }

  String get _hint {
    final args = Get.arguments;
    if (args is String && args.trim().isNotEmpty) return args;
    return 'Align the barcode inside the frame to fill this form.';
  }
}
