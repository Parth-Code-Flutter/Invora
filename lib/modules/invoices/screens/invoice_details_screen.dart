import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_card.dart';
import '../controllers/invoice_details_controller.dart';

class InvoiceDetailsScreen extends GetView<InvoiceDetailsController> {
  const InvoiceDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice details')),
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
