import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_filter_chip.dart';
import '../../../app/widgets/app_button.dart';
import '../../../data/services/invoice_pdf_service.dart';
import '../controllers/invoice_preview_controller.dart';

class InvoicePreviewScreen extends GetView<InvoicePreviewController> {
  const InvoicePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Invoice preview'),
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
              child: PdfPreview(
                key: ValueKey(selected),
                build: (_) => controller.build(),
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                allowPrinting: false,
                allowSharing: false,
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        final invoice = controller.invoice.value;
        if (invoice == null) return const SizedBox.shrink();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: AppButton(
              onPressed:
                  controller.isSavingDocument.value ||
                      controller.validationError.value != null
                  ? null
                  : controller.saveDocument,
              icon: Icons.check_rounded,
              label: 'Save invoice',
              isLoading: controller.isSavingDocument.value,
            ),
          ),
        );
      }),
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
