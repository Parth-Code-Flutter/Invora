import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/enums/item_type.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/utils/tax_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_entity_header.dart';
import '../../../data/models/invoice_model.dart';
import '../controllers/product_details_controller.dart';

class ProductDetailsScreen extends GetView<ProductDetailsController> {
  const ProductDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const AppBarTitle('Item details', subtitle: 'Catalog'),
        actions: [
          AppBarIconButton(
            tooltip: l10n('Edit item'),
            onPressed: () async {
              await Get.toNamed<void>(
                AppRoutes.productEdit,
                arguments: controller.itemId,
              );
              await controller.refreshItem();
            },
            icon: Icons.edit_outlined,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final item = controller.item.value;
        if (item == null) return const Center(child: Text('Item not found.'));
        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.horizontalPadding(context),
            vertical: ResponsiveUtils.height(context, 20),
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveUtils.formMaxWidth(context),
                ),
                child: Column(
                  children: [
                    AppEntityHeader(
                      icon: Icon(
                        item.type == ItemType.product
                            ? Icons.inventory_2_outlined
                            : Icons.design_services_outlined,
                      ),
                      title: item.name,
                      subtitle: '${item.type.label} • ${item.unit}',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            label: 'Sale price',
                            value: CurrencyUtils.formatMinor(
                              item.salePriceMinor,
                              symbol: controller.currencySymbol.value,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            label: 'GST rate',
                            value: TaxUtils.formatBasisPoints(
                              item.taxRateBasisPoints,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Item information',
                            style: AppTextStyles.sectionTitle,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(label: 'Type', value: item.type.label),
                          _InfoRow(label: 'Unit', value: item.unit),
                          _InfoRow(label: 'HSN/SAC', value: item.hsnSac),
                          _InfoRow(
                            label: 'Description',
                            value: item.description,
                          ),
                          ...item.attributes.map(
                            (attribute) => _InfoRow(
                              label: attribute.label,
                              value: attribute.value,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppConstrainedAction(
                      child: AppButton(
                        onPressed: () => Get.toNamed<void>(
                          AppRoutes.invoiceCreate,
                          arguments: InvoiceEditorArgs(productId: item.id),
                        ),
                        icon: Icons.receipt_long_outlined,
                        label: 'Create invoice with this item',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Text(value, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.small),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, child: Text(label, style: AppTextStyles.small)),
          Expanded(child: Text(value!, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
