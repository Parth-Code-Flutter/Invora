import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_grouped_tile.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/purchase_order_model.dart';
import '../controllers/purchase_order_controller.dart';

class PurchaseOrderListScreen extends GetView<PurchaseOrderListController> {
  const PurchaseOrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const AppBarTitle('Purchase orders'),
        actions: [
          AppBarIconButton(
            tooltip: l10n('Add purchase order'),
            onPressed: controller.openCreate,
            icon: Icons.add_rounded,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.openCreate,
        child: const Icon(Icons.add_rounded),
      ),
      body: Obx(() {
        final rows = controller.visible;
        if (controller.items.isEmpty) {
          return AppEmptyState(
            illustration: AppEmptyIllustration.clipboard,
            title: 'No purchase orders yet',
            message:
                'Order from a supplier, receive goods in one or more deliveries, then convert remaining received quantity into purchase bills. The PO does not change stock or payable.',
            actionLabel: 'Add purchase order',
            onAction: controller.openCreate,
          );
        }
        return ResponsiveContent(
          tabletMaxWidth: 720,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: TextField(
                  onChanged: controller.search,
                  decoration: const InputDecoration(
                    hintText: 'Search number or supplier',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              if (rows.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    illustration: AppEmptyIllustration.search,
                    title: 'No purchase orders found',
                    message: 'Try a different number or supplier name.',
                  ),
                )
              else
                SliverList.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = rows[index];
                    return AppGroupedTile(
                      onTap: () => controller.openDetails(item),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.orderNumber,
                                  style: AppTextStyles.listName,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.supplierName}  ·  ${_date(item.orderDate)}',
                                  style: AppTextStyles.secondaryBody,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            PurchaseOrderLabels.status(item.status),
                            style: AppTextStyles.caption.copyWith(
                              color:
                                  item.status == PurchaseOrderStatus.cancelled
                                  ? AppColors.error
                                  : AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      }),
    );
  }
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
