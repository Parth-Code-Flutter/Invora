import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/enums/item_type.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/utils/tax_utils.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_search_field.dart';
import '../../../data/models/product_service_model.dart';
import '../controllers/product_list_controller.dart';

class ProductListScreen extends GetView<ProductListController> {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products & services')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed<void>(AppRoutes.productAdd),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add item'),
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
                  hint: 'Search name, description or HSN/SAC',
                ),
                ResponsiveUtils.verticalGap(context, 10),
                Obx(
                  () => Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: controller.selectedType.value == null,
                        onSelected: () => controller.selectType(null),
                      ),
                      ResponsiveUtils.horizontalGap(context, 8),
                      _FilterChip(
                        label: 'Products',
                        selected:
                            controller.selectedType.value == ItemType.product,
                        onSelected: () =>
                            controller.selectType(ItemType.product),
                      ),
                      ResponsiveUtils.horizontalGap(context, 8),
                      _FilterChip(
                        label: 'Services',
                        selected:
                            controller.selectedType.value == ItemType.service,
                        onSelected: () =>
                            controller.selectType(ItemType.service),
                      ),
                    ],
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
      builder: (context) => AlertDialog(
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
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
      onTap: () =>
          Get.toNamed<void>(AppRoutes.productDetails, arguments: item.id),
      child: Row(
        children: [
          CircleAvatar(
            radius: ResponsiveUtils.width(context, 24),
            backgroundColor: item.type == ItemType.product
                ? AppColors.primaryLight
                : AppColors.secondaryLight,
            child: Icon(
              item.type == ItemType.product
                  ? Icons.inventory_2_outlined
                  : Icons.design_services_outlined,
              color: item.type == ItemType.product
                  ? AppColors.primary
                  : AppColors.secondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTextStyles.cardTitle),
                const SizedBox(height: 3),
                Text(
                  '${item.type.label} • ${item.unit}',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyUtils.formatMinor(
                    item.salePriceMinor,
                    symbol: currencySymbol,
                  ),
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 3),
                Text(
                  'GST ${TaxUtils.formatBasisPoints(item.taxRateBasisPoints)}',
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'edit') {
                Get.toNamed<void>(AppRoutes.productEdit, arguments: item.id);
              } else if (action == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}
