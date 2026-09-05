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
import '../../../app/widgets/app_pair_tabs.dart';
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
          Obx(
            () => AppSegmentTabs(
              labels: const ['All', 'Products', 'Services'],
              icons: const [
                Icons.grid_view_rounded,
                Icons.inventory_2_outlined,
                Icons.design_services_outlined,
              ],
              counts: [
                controller.countFor(null),
                controller.countFor(ItemType.product),
                controller.countFor(ItemType.service),
              ],
              index: switch (controller.selectedType.value) {
                null => 0,
                ItemType.product => 1,
                ItemType.service => 2,
              },
              onChanged: (index) => controller.selectType(switch (index) {
                1 => ItemType.product,
                2 => ItemType.service,
                _ => null,
              }),
            ),
          ),
          Expanded(
            child: Obx(() {
              final typeIndex = switch (controller.selectedType.value) {
                null => 0,
                ItemType.product => 1,
                ItemType.service => 2,
              };
              final Widget inner;
              if (controller.isLoading.value) {
                inner = const AppListSkeleton();
              } else if (controller.loadError.value != null) {
                inner = AppEmptyState(
                  illustration: AppEmptyIllustration.error,
                  title: 'Catalog unavailable',
                  message:
                      'Your saved items are unchanged. Try loading them again.',
                  actionLabel: 'Try again',
                  onAction: controller.retry,
                );
              } else if (controller.items.isEmpty) {
                final searching = controller.searchQuery.value.isNotEmpty;
                final filtered = controller.selectedType.value != null;
                inner = AppEmptyState(
                  illustration: searching
                      ? AppEmptyIllustration.search
                      : filtered &&
                            controller.selectedType.value == ItemType.service
                      ? AppEmptyIllustration.clipboard
                      : AppEmptyIllustration.package,
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
              } else {
                final columns = ResponsiveUtils.gridColumns(context);
                final horizontal = ResponsiveUtils.horizontalPadding(context);
                final showType = controller.selectedType.value == null;
                Widget tile(
                  int index, {
                  required AppGroupedPosition position,
                }) => AppListEntrance(
                  index: index,
                  child: _ProductCatalogTile(
                    item: controller.items[index],
                    currencySymbol: controller.currencySymbol.value,
                    showType: showType,
                    onHandScaled: controller.onHandFor(controller.items[index]),
                    position: position,
                    onDelete: () =>
                        _confirmDelete(context, controller.items[index]),
                  ),
                );
                if (columns == 1) {
                  final count = controller.items.length;
                  inner = ListView.builder(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      0,
                      horizontal,
                      100,
                    ),
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
                } else {
                  inner = ListView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      2,
                      horizontal,
                      100,
                    ),
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
                }
              }
              return AppSwipeTabs(
                index: typeIndex,
                length: 3,
                onChanged: (index) => controller.selectType(switch (index) {
                  1 => ItemType.product,
                  2 => ItemType.service,
                  _ => null,
                }),
                child: inner,
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

BorderRadius _catalogRadius(AppGroupedPosition position) {
  const radius = Radius.circular(12);
  return switch (position) {
    AppGroupedPosition.single => const BorderRadius.all(radius),
    AppGroupedPosition.start => const BorderRadius.vertical(top: radius),
    AppGroupedPosition.end => const BorderRadius.vertical(bottom: radius),
    AppGroupedPosition.middle => BorderRadius.zero,
  };
}
