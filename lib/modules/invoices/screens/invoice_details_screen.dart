import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/enums/invoice_status.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_card.dart';
import '../../../data/models/invoice_model.dart';
import '../controllers/invoice_details_controller.dart';

class InvoiceDetailsScreen extends GetView<InvoiceDetailsController> {
  const InvoiceDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.invoice.value?.documentType == DocumentType.quotation
                ? 'Quotation details'
                : 'Invoice details',
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Preview PDF',
            onPressed: () => Get.toNamed<void>(
              AppRoutes.invoicePreview,
              arguments: controller.invoice.value?.id,
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          Obx(
            () => IconButton(
              tooltip: 'Edit invoice',
              onPressed:
                  controller.invoice.value?.status == InvoiceStatus.cancelled
                  ? null
                  : controller.edit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ),
          Obx(
            () => PopupMenuButton<String>(
              onSelected: (action) => _handleAction(context, action),
              itemBuilder: (_) =>
                  controller.invoice.value?.documentType ==
                      DocumentType.quotation
                  ? const [
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Text('Duplicate'),
                      ),
                      PopupMenuItem(value: 'sent', child: Text('Mark sent')),
                      PopupMenuItem(
                        value: 'accepted',
                        child: Text('Mark accepted'),
                      ),
                      PopupMenuItem(
                        value: 'rejected',
                        child: Text('Mark rejected'),
                      ),
                      PopupMenuItem(
                        value: 'convert',
                        child: Text('Convert to invoice'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete quotation'),
                      ),
                    ]
                  : const [
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Text('Duplicate'),
                      ),
                      PopupMenuItem(
                        value: 'payment',
                        child: Text('Update payment'),
                      ),
                      PopupMenuItem(
                        value: 'cancel',
                        child: Text('Cancel invoice'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete invoice'),
                      ),
                    ],
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final invoice = controller.invoice.value;
        if (invoice == null) {
          return const Center(child: Text('Invoice not found.'));
        }
        final symbol = controller.currencySymbol.value;
        final sections = [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice.invoiceNumber, style: AppTextStyles.pageTitle),
                const SizedBox(height: 6),
                Text(
                  invoice.status.name.toUpperCase(),
                  style: AppTextStyles.small.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  CurrencyUtils.formatMinor(
                    invoice.calculation.grandTotalMinor,
                    symbol: symbol,
                  ),
                  style: AppTextStyles.displayAmount,
                ),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 10),
                Text(invoice.customer.name, style: AppTextStyles.cardTitle),
                if (invoice.customer.companyName != null)
                  Text(invoice.customer.companyName!),
                if (invoice.customer.mobile != null)
                  Text(invoice.customer.mobile!),
                if (invoice.customer.gstin != null)
                  Text('GSTIN: ${invoice.customer.gstin}'),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Items', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 8),
                ...invoice.items.asMap().entries.map((entry) {
                  final item = entry.value;
                  final total = invoice.calculation.items[entry.key].totalMinor;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name),
                    subtitle: Text(
                      '${QuantityUtils.toInputValue(item.quantityScaled)} ${item.unit} × ${CurrencyUtils.formatMinor(item.rateMinor, symbol: symbol)}',
                    ),
                    trailing: Text(
                      CurrencyUtils.formatMinor(total, symbol: symbol),
                    ),
                  );
                }),
              ],
            ),
          ),
          AppCard(
            child: Column(
              children: [
                _row(
                  'Grand total',
                  invoice.calculation.grandTotalMinor,
                  symbol,
                ),
                _row('Paid', invoice.calculation.paidAmountMinor, symbol),
                const Divider(),
                _row(
                  'Balance due',
                  invoice.calculation.balanceDueMinor,
                  symbol,
                ),
              ],
            ),
          ),
          if (invoice.notes != null || invoice.terms != null)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (invoice.notes != null) ...[
                    Text('Notes', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 6),
                    Text(invoice.notes!),
                  ],
                  if (invoice.terms != null) ...[
                    const SizedBox(height: 16),
                    Text('Terms', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 6),
                    Text(invoice.terms!),
                  ],
                ],
              ),
            ),
        ];
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtils.isTablet(context) ? 820 : 680,
            ),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.horizontalPadding(context),
                12,
                ResponsiveUtils.horizontalPadding(context),
                28,
              ),
              itemCount: sections.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) => sections[index],
            ),
          ),
        );
      }),
    );
  }

  Future<void> _handleAction(BuildContext context, String action) async {
    switch (action) {
      case 'duplicate':
        await controller.duplicate();
        return;
      case 'payment':
        await _showPaymentDialog(context);
        return;
      case 'cancel':
        final confirmed = await _confirm(
          context,
          title: 'Cancel invoice?',
          message: 'The invoice remains in your records but cannot be edited.',
          action: 'Cancel invoice',
        );
        if (confirmed) await controller.cancel();
        return;
      case 'sent':
        await controller.setQuotationStatus(InvoiceStatus.sent);
        return;
      case 'accepted':
        await controller.setQuotationStatus(InvoiceStatus.accepted);
        return;
      case 'rejected':
        await controller.setQuotationStatus(InvoiceStatus.rejected);
        return;
      case 'convert':
        await controller.convertToInvoice();
        return;
      case 'delete':
        final confirmed = await _confirm(
          context,
          title: 'Delete invoice?',
          message: 'This permanently removes the invoice and its saved items.',
          action: 'Delete',
        );
        if (confirmed) await controller.delete();
        return;
    }
  }

  Future<void> _showPaymentDialog(BuildContext context) async {
    final invoice = controller.invoice.value;
    if (invoice == null || invoice.status == InvoiceStatus.cancelled) return;
    final input = TextEditingController(
      text: CurrencyUtils.toInputValue(invoice.calculation.paidAmountMinor),
    );
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('Update payment'),
          content: TextField(
            controller: input,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Total amount paid',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final validation = await controller.updatePayment(input.text);
                if (validation == null && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                } else {
                  setState(() => error = validation);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    input.dispose();
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Back'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }
}

Widget _row(String label, int value, String symbol) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 7),
  child: Row(
    children: [
      Expanded(child: Text(label)),
      Text(
        CurrencyUtils.formatMinor(value, symbol: symbol),
        style: AppTextStyles.cardTitle,
      ),
    ],
  ),
);
