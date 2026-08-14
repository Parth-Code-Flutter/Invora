import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_dialog.dart';
import '../../../app/widgets/barcode_viewfinder.dart';
import '../../../data/models/product_form_args.dart';
import '../../../data/models/product_service_model.dart';
import '../../../data/models/scanned_invoice_line.dart';
import 'product_scan_controller.dart';
import 'product_scan_session.dart';

/// Route arguments for [ProductScanScreen].
class ProductScanArgs {
  const ProductScanArgs({this.quotation = false});
  final bool quotation;
}

/// Split camera + scanned-items workspace used while creating a document.
class ProductScanScreen extends StatefulWidget {
  const ProductScanScreen({super.key});

  @override
  State<ProductScanScreen> createState() => _ProductScanScreenState();
}

class _ProductScanScreenState extends State<ProductScanScreen> {
  final _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 800,
    facing: CameraFacing.back,
  );
  late final ProductScanController _controller;
  var _handlingUnknown = false;

  bool get _quotation {
    final args = Get.arguments;
    return args is ProductScanArgs && args.quotation;
  }

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ProductScanController>();
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handlingUnknown || _controller.isBusy.value) return;
    final code = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .map((value) => value.trim())
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (code.isEmpty) return;

    final product = await _controller.lookup(code);
    if (!mounted) return;
    if (product != null) {
      final result = _controller.acceptProduct(product: product, rawCode: code);
      if (result != ScanApplyResult.ignored) {
        HapticFeedback.selectionClick();
      }
      return;
    }

    _handlingUnknown = true;
    _controller.isBusy.value = true;
    try {
      await _scanner.pause();
      final created = await _offerUnknownProduct(code);
      if (created != null && mounted) {
        _controller.acceptProduct(product: created, rawCode: code);
        HapticFeedback.mediumImpact();
      }
    } finally {
      _handlingUnknown = false;
      _controller.isBusy.value = false;
      if (mounted) await _scanner.start();
    }
  }

  Future<ProductServiceModel?> _offerUnknownProduct(String code) async {
    final save = await showAppConfirmDialog(
      context: context,
      icon: Icons.qr_code_scanner_rounded,
      tone: AppDialogTone.info,
      title: 'No catalog item',
      message:
          'Nothing in your saved products matches $code. Save it as a new product to keep scanning.',
      confirmLabel: 'Save product',
      cancelLabel: 'Keep scanning',
    );
    if (!save || !mounted) return null;
    final result = await Get.toNamed<dynamic>(
      AppRoutes.productAdd,
      arguments: ProductFormArgs(initialSku: code),
    );
    return result is ProductServiceModel ? result : null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan items'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _scanner,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => _ScannerError(error: error),
                ),
                const IgnorePointer(child: Center(child: BarcodeViewfinder())),
                Positioned(
                  right: 14,
                  top: 14,
                  child: ValueListenableBuilder(
                    valueListenable: _scanner,
                    builder: (context, state, _) {
                      final on = state.torchState == TorchState.on;
                      if (state.torchState == TorchState.unavailable) {
                        return const SizedBox.shrink();
                      }
                      return _CameraChip(
                        icon: on
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        tooltip: l10n('Torch'),
                        selected: on,
                        onTap: _scanner.toggleTorch,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 6,
            child: Material(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: Obx(() {
                final lines = _controller.lines.toList(growable: false);
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Scanned items',
                                  style: AppTextStyles.sectionTitle,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_controller.uniqueItemCount} ${_controller.uniqueItemCount == 1 ? 'item' : 'items'} total',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'TOTAL',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textTertiary,
                                  letterSpacing: 0.6,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                CurrencyUtils.formatMinor(
                                  _controller.totalMinor,
                                  symbol: _controller.currencySymbol.value,
                                ),
                                style: AppTextStyles.cardTitle.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: lines.isEmpty
                          ? const _EmptyScanList()
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                              itemCount: lines.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) => _ScannedLineTile(
                                line: lines[index],
                                symbol: _controller.currencySymbol.value,
                                onIncrease: () =>
                                    _controller.incrementAt(index),
                                onDecrease: () =>
                                    _controller.decrementAt(index),
                              ),
                            ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: AppButton(
                          label: _quotation
                              ? 'Add to quotation'
                              : 'Add to invoice',
                          icon: Icons.playlist_add_check_rounded,
                          onPressed: lines.isEmpty
                              ? null
                              : () => Get.back<List<ScannedInvoiceLine>>(
                                  result: lines,
                                ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyScanList extends StatelessWidget {
  const _EmptyScanList();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_basket_outlined,
              size: 42,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text('List is empty', style: AppTextStyles.cardTitle),
            const SizedBox(height: 6),
            Text(
              'Point the camera at a product barcode. Matching catalog items appear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannedLineTile extends StatelessWidget {
  const _ScannedLineTile({
    required this.line,
    required this.symbol,
    required this.onIncrease,
    required this.onDecrease,
  });

  final ScannedInvoiceLine line;
  final String symbol;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.listName,
                ),
                const SizedBox(height: 3),
                Text(
                  CurrencyUtils.formatMinor(
                    line.product.salePriceMinor,
                    symbol: symbol,
                  ),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: line.quantityScaled <= 1000
                      ? 'Remove item'
                      : 'Decrease quantity',
                  onPressed: onDecrease,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    line.quantityScaled <= 1000
                        ? Icons.delete_outline_rounded
                        : Icons.remove_rounded,
                    size: 17,
                    color: line.quantityScaled <= 1000 ? AppColors.error : null,
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    QuantityUtils.toInputValue(line.quantityScaled),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n('Increase quantity'),
                  onPressed: onIncrease,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.add_rounded, size: 17),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraChip extends StatelessWidget {
  const _CameraChip({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary
          : Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            denied
                ? 'Camera permission is needed to scan barcodes. Enable it in Settings, then try again.'
                : 'The camera could not start. ${error.errorDetails?.message ?? ''}'
                      .trim(),
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
