import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/enums/item_type.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/utils/tax_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_dialog.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_filter_chip.dart';
import '../../../app/widgets/app_search_field.dart';
import '../../../data/models/product_service_model.dart';
import '../controllers/product_list_controller.dart';

class ProductListScreen extends GetView<ProductListController> {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add product or service',
        onPressed: () => Get.toNamed<void>(AppRoutes.productAdd),
        child: const Icon(Icons.add_rounded),
      ),
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Products & services'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtils.horizontalPadding(context),
              ResponsiveUtils.height(context, 8),
              ResponsiveUtils.horizontalPadding(context),
              ResponsiveUtils.height(context, 8),
            ),
            child: Column(
              children: [
                AppSearchField(
                  onChanged: controller.updateSearch,
                  hint: 'Search products or services',
                ),
                ResponsiveUtils.verticalGap(context, 10),
                Obx(
                  () => SizedBox(
                    height: 48,
                    child: ListView(
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
                const SizedBox(height: 8),
                Obx(
                  () => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${controller.items.length} saved items',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
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
              if (columns == 1) {
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 100),
                  itemCount: controller.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _ItemCard(
                    item: controller.items[index],
                    currencySymbol: controller.currencySymbol.value,
                    onDelete: () =>
                        _confirmDelete(context, controller.items[index]),
                  ),
                );
              }
              return GridView.builder(
                padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 100),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: ResponsiveUtils.height(context, 174),
                ),
                itemCount: controller.items.length,
                itemBuilder: (context, index) => _ItemCard(
                  item: controller.items[index],
                  currencySymbol: controller.currencySymbol.value,
                  onDelete: () =>
                      _confirmDelete(context, controller.items[index]),
                ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        icon: Icons.delete_outline_rounded,
        iconColor: AppColors.error,
        title: Text('Delete ${item.type.label.toLowerCase()}?'),
        content: Text(
          '${item.name} will be hidden from lists. Historical invoices will remain unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await controller.deleteItem(item);
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.currencySymbol,
    required this.onDelete,
  });
  final ProductServiceModel item;
  final String currencySymbol;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () =>
          Get.toNamed<void>(AppRoutes.productDetails, arguments: item.id),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.type == ItemType.product
                  ? AppColors.primaryLight
                  : AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              item.type == ItemType.product
                  ? Icons.inventory_2_outlined
                  : Icons.design_services_outlined,
              color: item.type == ItemType.product
                  ? AppColors.primary
                  : AppColors.secondary,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.name, style: AppTextStyles.cardTitle),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: item.type == ItemType.product
                            ? AppColors.primaryLight
                            : AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.type.label,
                        style: AppTextStyles.caption.copyWith(
                          color: item.type == ItemType.product
                              ? AppColors.primary
                              : AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.unit} • GST ${TaxUtils.formatBasisPoints(item.taxRateBasisPoints)}',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (item.attributes.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.attributes
                        .take(3)
                        .map((value) => value.value)
                        .join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  CurrencyUtils.formatMinor(
                    item.salePriceMinor,
                    symbol: currencySymbol,
                  ),
                  style: AppTextStyles.cardTitle,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Item actions',
            onPressed: () => _showActions(context),
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
