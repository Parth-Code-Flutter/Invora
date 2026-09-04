import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/enums/item_type.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/utils/tax_utils.dart';
import '../../../app/widgets/app_amount_text.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_dialog.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_grouped_tile.dart';
import '../../../app/widgets/app_list_motion.dart';
import '../../../app/widgets/app_main_navigation.dart';
import '../../../app/widgets/app_search_app_bar.dart';
import '../../../app/widgets/app_shell.dart';
import '../../../data/models/product_service_model.dart';
import '../controllers/product_list_controller.dart';
import '../widgets/product_cover_thumb.dart';

class ProductListScreen extends GetView<ProductListController> {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return AppShell(
      destination: MainDestination.products,
      floatingActionButton: FloatingActionButton(
        tooltip: l10n('Add product or service'),
        onPressed: () => Get.toNamed<void>(AppRoutes.productAdd),
        child: const Icon(Icons.add_rounded),
      ),
      appBar: AppSearchAppBar(
        leading: canPop ? const AppBackButton() : null,
        title: 'Products & services',
        hint: 'Search products or services',
        onChanged: controller.updateSearch,
        actions: [
          AppBarIconButton(
            tooltip: l10n('Scan barcode'),
            onPressed: () => Get.toNamed<void>(AppRoutes.catalogScan),
            icon: Icons.qr_code_scanner_rounded,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtils.horizontalPadding(context),
              10,
              ResponsiveUtils.horizontalPadding(context),
              8,
            ),
            child: Obx(
              () => _CatalogTypeSelector(
                selected: controller.selectedType.value,
                allCount: controller.countFor(null),
                productCount: controller.countFor(ItemType.product),
                serviceCount: controller.countFor(ItemType.service),
                onChanged: controller.selectType,
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const AppListSkeleton();
              }
              if (controller.loadError.value != null) {
                return AppEmptyState(
                  icon: Icons.sync_problem_rounded,
                  title: 'Catalog unavailable',
                  message:
                      'Your saved items are unchanged. Try loading them again.',
                  actionLabel: 'Try again',
                  onAction: controller.retry,
                );
              }
              if (controller.items.isEmpty) {
                final searching = controller.searchQuery.value.isNotEmpty;
                final filtered = controller.selectedType.value != null;
                return AppEmptyState(
                  icon: filtered
                      ? controller.selectedType.value == ItemType.product
                            ? Icons.inventory_2_outlined
                            : Icons.design_services_outlined
                      : Icons.inventory_2_outlined,
                  title: searching
                      ? 'No matching items'
                      : filtered
                      ? 'No ${controller.selectedType.value!.label.toLowerCase()}s yet'
                      : 'Your catalog is empty',
                  message: searching
                      ? 'Try a different name, detail, HSN/SAC, or filter.'
                      : filtered
                      ? 'Create your first ${controller.selectedType.value!.label.toLowerCase()} to reuse it on invoices.'
                      : 'Save products and services once, then reuse them on every invoice.',
                  actionLabel: searching ? null : 'Add item',
                  onAction: searching
                      ? null
                      : () => Get.toNamed<void>(AppRoutes.productAdd),
                );
              }
              final columns = ResponsiveUtils.gridColumns(context);
              final horizontal = ResponsiveUtils.horizontalPadding(context);
              final showType = controller.selectedType.value == null;
              Widget tile(int index, {required AppGroupedPosition position}) =>
                  AppListEntrance(
                    index: index,
                    child: _ProductCatalogTile(
                      item: controller.items[index],
                      currencySymbol: controller.currencySymbol.value,
                      showType: showType,
                      onHandScaled: controller.onHandFor(
                        controller.items[index],
                      ),
                      position: position,
                      onDelete: () =>
                          _confirmDelete(context, controller.items[index]),
                    ),
                  );
              if (columns == 1) {
                final count = controller.items.length;
                return ListView.builder(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 100),
                  itemCount: count + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              '$count ${count == 1 ? 'item' : 'items'}',
                              style: AppTextStyles.caption.copyWith(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Name · A–Z',
                              style: AppTextStyles.caption.copyWith(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return tile(
                      index - 1,
                      position: AppGroupedPositionX.resolve(index - 1, count),
                    );
                  },
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
                            SizedBox(
                              width: width,
                              child: tile(
                                index,
                                position: AppGroupedPosition.single,
                              ),
                            ),
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
    required this.position,
    required this.onDelete,
    this.onHandScaled,
  });

  final ProductServiceModel item;
  final String currencySymbol;
  final bool showType;
  final int? onHandScaled;
  final AppGroupedPosition position;
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
      if (item.hsnSac?.trim().isNotEmpty ?? false) 'HSN ${item.hsnSac!.trim()}',
      'GST ${TaxUtils.formatBasisPoints(item.taxRateBasisPoints)}',
    ].join(' · ');
    final attributes = item.attributes.isEmpty
        ? null
        : item.attributes.take(3).map((value) => value.value).join(' · ');

    return GestureDetector(
      onLongPress: () => _showActions(context),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: _catalogRadius(position),
            border: Border(
              top:
                  position == AppGroupedPosition.start ||
                      position == AppGroupedPosition.single
                  ? BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    )
                  : BorderSide.none,
              left: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
              right: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
              bottom: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
          ),
          child: InkWell(
            onTap: () =>
                Get.toNamed<void>(AppRoutes.productDetails, arguments: item.id),
            borderRadius: _catalogRadius(position),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 2, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ProductCoverThumb(
                    imagePaths: item.imagePaths,
                    type: item.type,
                    size: 44,
                    radius: 12,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.listName,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            meta,
                            ?attributes,
                            if (onHandScaled != null)
                              'On hand ${QuantityUtils.formatSigned(onHandScaled!)} ${item.unit}',
                          ].join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: secondary,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 96),
                        child: AppAmountText(
                          amountMinor: item.salePriceMinor,
                          symbol: currencySymbol,
                          style: AppTextStyles.listAmount,
                        ),
                      ),
                      Text(
                        '/ ${item.unit}',
                        style: AppTextStyles.caption.copyWith(
                          color: tertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    tooltip: l10n('Item actions'),
                    onPressed: () => _showActions(context),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      foregroundColor: tertiary,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.more_horiz_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
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

class _CatalogTypeSelector extends StatelessWidget {
  const _CatalogTypeSelector({
    required this.selected,
    required this.allCount,
    required this.productCount,
    required this.serviceCount,
    required this.onChanged,
  });

  final ItemType? selected;
  final int allCount;
  final int productCount;
  final int serviceCount;
  final ValueChanged<ItemType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _CatalogTypeOption(
            label: 'All',
            count: allCount,
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          _CatalogTypeOption(
            label: 'Products',
            count: productCount,
            selected: selected == ItemType.product,
            onTap: () => onChanged(ItemType.product),
          ),
          _CatalogTypeOption(
            label: 'Services',
            count: serviceCount,
            selected: selected == ItemType.service,
            onTap: () => onChanged(ItemType.service),
          ),
        ],
      ),
    );
  }
}

class _CatalogTypeOption extends StatelessWidget {
  const _CatalogTypeOption({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? AppColors.darkSurface : Colors.white;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label, $count',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? selectedColor : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? .28 : .08,
                        ),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small.copyWith(
                      color: selected
                          ? (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary)
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '$count',
                    style: AppTextStyles.caption.copyWith(
                      color: selected
                          ? AppColors.secondary
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textTertiary),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

BorderRadius _catalogRadius(AppGroupedPosition position) {
  const radius = Radius.circular(12);
  return switch (position) {
    AppGroupedPosition.single => const BorderRadius.all(radius),
    AppGroupedPosition.start => const BorderRadius.vertical(top: radius),
    AppGroupedPosition.end => const BorderRadius.vertical(bottom: radius),
    AppGroupedPosition.middle => BorderRadius.zero,
  };
}
