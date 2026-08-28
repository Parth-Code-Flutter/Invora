import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_grouped_tile.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/delivery_challan_model.dart';
import '../controllers/delivery_challan_controller.dart';

class DeliveryChallanListScreen extends GetView<DeliveryChallanListController> {
  const DeliveryChallanListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const AppBarTitle('Delivery challans'),
        actions: [
          AppBarIconButton(
            tooltip: l10n('Add challan'),
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
            icon: Icons.local_shipping_outlined,
            title: 'No delivery challans yet',
            message:
                'Start from items or an estimate, then convert remaining quantity later. Use an invoice only for leftover delivery of an already billed sale.',
            actionLabel: 'Add challan',
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
                    hintText: 'Search number or customer',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              if (rows.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No challans found',
                    message: 'Try a different number or customer name.',
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
                                  item.challanNumber,
                                  style: AppTextStyles.listName,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.customerName}  ·  ${_date(item.challanDate)}',
                                  style: AppTextStyles.secondaryBody,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            DeliveryChallanLabels.status(item.status),
                            style: AppTextStyles.caption.copyWith(
                              color:
                                  item.status == DeliveryChallanStatus.cancelled
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
