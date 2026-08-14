import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_filter_chip.dart';
import '../../../app/widgets/app_swipe_action.dart';
import '../../../data/services/invoice_pdf_service.dart';
import '../controllers/invoice_preview_controller.dart';

class InvoicePreviewScreen extends GetView<InvoicePreviewController> {
  const InvoicePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Obx(
          () => Text(
            controller.isReadOnly.value ? 'Generated PDF' : 'Invoice preview',
          ),
        ),
        actions: [
          IconButton(
            onPressed: controller.savePdf,
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Save PDF',
          ),
          IconButton(
            onPressed: controller.share,
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share PDF',
          ),
          IconButton(
            onPressed: controller.print,
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.invoice.value == null ||
            controller.business.value == null) {
          return const Center(child: Text('Invoice preview is unavailable.'));
        }
        if (controller.validationError.value != null) {
          return _IncompleteInvoice(message: controller.validationError.value!);
        }
        final selected = controller.template.value;
        return Column(
          children: [
            if (!controller.isReadOnly.value)
              SizedBox(
                height: 58,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  scrollDirection: Axis.horizontal,
                  children: InvoiceTemplate.values
                      .map(
                        (template) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AppFilterChip(
                            label: template.label,
                            icon: Icons.description_outlined,
                            selected: selected == template,
                            onSelected: (_) =>
                                controller.selectTemplate(template),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            Expanded(
              child: PdfPreview.builder(
                key: ValueKey(selected),
                build: (_) => controller.build(),
                dpi: 160,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                allowPrinting: false,
                allowSharing: false,
                pagesBuilder: (_, pages) => ZoomablePdfPages(pages: pages),
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        final invoice = controller.invoice.value;
        if (invoice == null || controller.isReadOnly.value) {
          return const SizedBox.shrink();
        }
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: AppSwipeAction(
              onCompleted:
                  controller.isSavingDocument.value ||
                      controller.validationError.value != null
                  ? null
                  : controller.saveDocument,
              label: invoice.id == null
                  ? 'Swipe to create invoice'
                  : 'Swipe to update invoice',
              isLoading: controller.isSavingDocument.value,
            ),
          ),
        );
      }),
    );
  }
}

class ZoomablePdfPages extends StatefulWidget {
  const ZoomablePdfPages({required this.pages, super.key});

  final List<PdfPreviewPageData> pages;

  @override
  State<ZoomablePdfPages> createState() => _ZoomablePdfPagesState();
}

class _ZoomablePdfPagesState extends State<ZoomablePdfPages> {
  final TransformationController _transformation = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_transformation.value.getMaxScaleOnAxis() > 1.05) {
      _transformation.value = Matrix4.identity();
      return;
    }
    final position = _doubleTapDetails?.localPosition ?? Offset.zero;
    const scale = 2.25;
    _transformation.value = Matrix4.identity()
      ..translateByDouble(
        -position.dx * (scale - 1),
        -position.dy * (scale - 1),
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onDoubleTapDown: (details) => _doubleTapDetails = details,
            onDoubleTap: _handleDoubleTap,
            child: InteractiveViewer(
              transformationController: _transformation,
              minScale: 1,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(80),
              panEnabled: true,
              scaleEnabled: true,
              trackpadScrollCausesScale: true,
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final pageWidth = constraints.maxWidth - 20;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.pages
                            .map(
                              (page) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x33000000),
                                        blurRadius: 5,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: const Color(0x22000000),
                                    ),
                                  ),
                                  child: Image(
                                    image: page.image,
                                    width: pageWidth,
                                    fit: BoxFit.fitWidth,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white).withValues(
                  alpha: 0.86,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x1A000000), blurRadius: 8),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pinch_rounded, size: 16),
                    SizedBox(width: 6),
                    Text('Pinch to zoom', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IncompleteInvoice extends StatelessWidget {
  const _IncompleteInvoice({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 52,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Invoice is incomplete',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
