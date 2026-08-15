import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/enums/item_type.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/utils/tax_utils.dart';
import '../../../app/widgets/app_amount_text.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_dialog.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_filter_chip.dart';
import '../../../app/widgets/app_grouped_tile.dart';
import '../../../app/widgets/app_list_motion.dart';
import '../../../app/widgets/app_search_app_bar.dart';
import '../../../data/models/product_service_model.dart';
import '../controllers/product_list_controller.dart';

class ProductListScreen extends GetView<ProductListController> {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: l10n('Add product or service'),
        onPressed: () => Get.toNamed<void>(AppRoutes.productAdd),
        child: const Icon(Icons.add_rounded),
      ),
      appBar: AppSearchAppBar(
        leading: const AppBackButton(),
        title: 'Products & services',
        titleSuffix: Obx(
          () => Text(
            '(${controller.items.length})',
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        hint: 'Search products or services',
        onChanged: controller.updateSearch,
        actions: [
          IconButton(
            tooltip: l10n('Scan barcode'),
            onPressed: () => Get.toNamed<void>(AppRoutes.catalogScan),
            icon: const Icon(Icons.qr_code_scanner_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtils.horizontalPadding(context),
              8,
              ResponsiveUtils.horizontalPadding(context),
              10,
            ),
            child: SizedBox(
              height: 42,
              child: Obx(
                () => ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    AppFilterChip(
                      label: 'All',
                      icon: Icons.grid_view_rounded,
                      selected: controller.selectedType.value == null,
                      onSelected: (_) => controller.selectType(null),
                    ),
                    ResponsiveUtils.horizontalGap(context, 8),
                    AppFilterChip(
                      label: 'Products',
                      icon: Icons.inventory_2_outlined,
                      selected:
                          controller.selectedType.value == ItemType.product,
                      onSelected: (_) =>
                          controller.selectType(ItemType.product),
                    ),
                    ResponsiveUtils.horizontalGap(context, 8),
                    AppFilterChip(
                      label: 'Services',
                      icon: Icons.design_services_outlined,
                      selected:
                          controller.selectedType.value == ItemType.service,
                      onSelected: (_) =>
                          controller.selectType(ItemType.service),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const AppListSkeleton();
              }
              if (controller.items.isEmpty) {
                return AppEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: controller.searchQuery.value.isEmpty
                      ? 'No products or services yet'
                      : 'No items found',
                  message: controller.searchQuery.value.isEmpty
                      ? 'Save frequently invoiced items for a faster workflow.'
                      : 'Try another search or filter.',
                  actionLabel: controller.searchQuery.value.isEmpty
                      ? 'Add item'
                      : null,
                  onAction: controller.searchQuery.value.isEmpty
                      ? () => Get.toNamed<void>(AppRoutes.productAdd)
                      : null,
                );
              }
              final columns = ResponsiveUtils.gridColumns(context);
              final horizontal = ResponsiveUtils.horizontalPadding(context);
              final showType = controller.selectedType.value == null;
              Widget tile(int index) => AppListEntrance(
                index: index,
                child: _ProductCatalogTile(
                  item: controller.items[index],
                  currencySymbol: controller.currencySymbol.value,
                  showType: showType,
                  onDelete: () =>
                      _confirmDelete(context, controller.items[index]),
                ),
              );
              if (columns == 1) {
                return ListView.separated(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(horizontal, 2, horizontal, 100),
                  itemCount: controller.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) => tile(index),
                );
              }
              return ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(horizontal, 2, horizontal, 100),
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 8.0;
                      final width =
                          (constraints.maxWidth - gap * (columns - 1)) /
                          columns;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (
                            var index = 0;
                            index < controller.items.length;
                            index++
                          )
                            SizedBox(width: width, child: tile(index)),
                        ],
                      );
                    },
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ProductServiceModel item,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      destructive: true,
      title: 'Delete ${item.type.label.toLowerCase()}?',
      message:
          '${item.name} will be hidden from lists. Historical invoices will remain unchanged.',
      confirmLabel: 'Delete',
    );
    if (confirmed) await controller.deleteItem(item);
  }
}

class _ProductCatalogTile extends StatelessWidget {
  const _ProductCatalogTile({
    required this.item,
    required this.currencySymbol,
    required this.showType,
    required this.onDelete,
  });

  final ProductServiceModel item;
  final String currencySymbol;
  final bool showType;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final tertiary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textTertiary;
    final meta = [
      if (showType) item.type.label,
      item.unit,
      'GST ${TaxUtils.formatBasisPoints(item.taxRateBasisPoints)}',
    ].join(' · ');
    final attributes = item.attributes.isEmpty
        ? null
        : item.attributes.take(3).map((value) => value.value).join(' · ');

    return AppGroupedTile(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      onTap: () =>
          Get.toNamed<void>(AppRoutes.productDetails, arguments: item.id),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.listName,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 108),
                      child: AppAmountText(
                        amountMinor: item.salePriceMinor,
                        symbol: currencySymbol,
                        style: AppTextStyles.listAmount,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: secondary,
                    fontSize: 11,
                  ),
                ),
                if (attributes != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    attributes,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: tertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: l10n('Item actions'),
            onPressed: () => _showActions(context),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: secondary,
            ),
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
    );
  }

  Future<void> _showActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(item.name, style: AppTextStyles.sectionTitle),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit item'),
              subtitle: const Text('Update pricing and product details'),
              onTap: () => Navigator.pop(sheetContext, 'edit'),
            ),
            ListTile(
              textColor: AppColors.error,
              iconColor: AppColors.error,
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Delete item'),
              subtitle: const Text('Historical invoices remain unchanged'),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == 'edit') {
      Get.toNamed<void>(AppRoutes.productEdit, arguments: item.id);
    } else if (action == 'delete') {
      onDelete();
    }
  }
}
