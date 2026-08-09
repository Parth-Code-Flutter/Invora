import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../../data/services/invoice_pdf_service.dart';
import '../controllers/invoice_preview_controller.dart';

class InvoicePreviewScreen extends GetView<InvoicePreviewController> {
  const InvoicePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice preview'),
        actions: [
          IconButton(
            onPressed: controller.save,
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
                        child: ChoiceChip(
                          label: Text(template.label),
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
    );
  }
}
