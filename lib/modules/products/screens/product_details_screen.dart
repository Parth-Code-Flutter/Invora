import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/enums/item_type.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/utils/tax_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../data/models/invoice_model.dart';
import '../controllers/product_details_controller.dart';

class ProductDetailsScreen extends GetView<ProductDetailsController> {
  const ProductDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
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
      if (item == null) {
        return AppEmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Item not found',
          message: 'This catalog item may have been removed.',
          actionLabel: 'Go back',
          onAction: Get.back<void>,
        );
      }
      final attributes = item.attributes
          .where((attribute) => attribute.value.trim().isNotEmpty)
          .map((attribute) => MapEntry(attribute.label, attribute.value.trim()))
          .toList(growable: false);
      final description = item.description?.trim();
      final code = item.hsnSac?.trim();
      final hasInformation =
          (code?.isNotEmpty ?? false) ||
          attributes.isNotEmpty ||
          (description?.isNotEmpty ?? false);
      return ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          ResponsiveUtils.horizontalPadding(context),
          ResponsiveUtils.height(context, 16),
          ResponsiveUtils.horizontalPadding(context),
          28,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveUtils.formMaxWidth(context),
              ),
              child: Column(
                children: [
                  _ItemOverviewCard(
                    name: item.name,
                    type: item.type,
                    unit: item.unit,
                    price: CurrencyUtils.formatMinor(
                      item.salePriceMinor,
                      symbol: controller.currencySymbol.value,
                    ),
                    gst: TaxUtils.formatBasisPoints(item.taxRateBasisPoints),
                  ),
                  if (hasInformation) ...[
                    const SizedBox(height: 14),
                    _ItemInformationCard(
                      codeLabel: item.type == ItemType.product
                          ? 'HSN code'
                          : 'SAC code',
                      code: code,
                      attributes: attributes,
                      description: description,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }),
    bottomNavigationBar: Obx(() {
      final item = controller.item.value;
      if (controller.isLoading.value || item == null) {
        return const SizedBox.shrink();
      }
      return SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            ResponsiveUtils.horizontalPadding(context),
            10,
            ResponsiveUtils.horizontalPadding(context),
            12,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkBorder
                    : AppColors.border,
              ),
            ),
          ),
          child: AppConstrainedAction(
            child: AppButton(
              onPressed: () => Get.toNamed<void>(
                AppRoutes.invoiceCreate,
                arguments: InvoiceEditorArgs(productId: item.id),
              ),
              label: 'Use in invoice',
              trailingIcon: Icons.arrow_forward_rounded,
            ),
          ),
        ),
      );
    }),
  );
}

class _ItemOverviewCard extends StatelessWidget {
  const _ItemOverviewCard({
    required this.name,
    required this.type,
    required this.unit,
    required this.price,
    required this.gst,
  });

  final String name;
  final ItemType type;
  final String unit;
  final String price;
  final String gst;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = type == ItemType.product
        ? AppColors.primary
        : AppColors.secondary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  type == ItemType.product
                      ? Icons.inventory_2_outlined
                      : Icons.design_services_outlined,
                  color: accent,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sectionTitle.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${type.label} · priced per $unit',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryValue(label: 'PRICE', value: price),
                ),
                const _SummaryDivider(),
                Expanded(
                  child: _SummaryValue(label: 'UNIT', value: unit),
                ),
                const _SummaryDivider(),
                Expanded(
                  child: _SummaryValue(label: 'GST', value: gst),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkTextSecondary
              : AppColors.textTertiary,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: .5,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 34,
    margin: const EdgeInsets.symmetric(horizontal: 10),
    color: Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBorder
        : AppColors.border,
  );
}

class _ItemInformationCard extends StatelessWidget {
  const _ItemInformationCard({
    required this.codeLabel,
    required this.code,
    required this.attributes,
    required this.description,
  });

  final String codeLabel;
  final String? code;
  final List<MapEntry<String, String>> attributes;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[
      if (code?.isNotEmpty ?? false) MapEntry(codeLabel, code!),
      ...attributes,
    ];
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Item information', style: AppTextStyles.sectionTitle),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (var index = 0; index < rows.length; index++) ...[
              _DetailRow(label: rows[index].key, value: rows[index].value),
              if (index < rows.length - 1 || (description?.isNotEmpty ?? false))
                const Divider(height: 1),
            ],
          ],
          if (description?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Text(
              'Invoice description',
              style: AppTextStyles.caption.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(description!, style: AppTextStyles.body.copyWith(height: 1.4)),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 11),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
