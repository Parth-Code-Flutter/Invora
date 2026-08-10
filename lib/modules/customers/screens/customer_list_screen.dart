import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_search_app_bar.dart';
import '../../../app/widgets/app_main_navigation.dart';
import '../../../app/widgets/app_module_banner.dart';
import '../../../data/models/customer_model.dart';
import '../controllers/customer_list_controller.dart';

class CustomerListScreen extends GetView<CustomerListController> {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppSearchAppBar(
        title: 'Customers',
        hint: 'Name, mobile or GSTIN',
        onChanged: controller.updateSearch,
      ),
      bottomNavigationBar: const AppMainNavigation(
        current: MainDestination.customers,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtils.horizontalPadding(context),
              ResponsiveUtils.height(context, 8),
              ResponsiveUtils.horizontalPadding(context),
              ResponsiveUtils.height(context, 12),
            ),
            child: Column(
              children: [
                AppModuleBanner(
                  title: 'People you bill',
                  subtitle: 'Keep billing details ready for the next invoice.',
                  icon: Icons.people_alt_outlined,
                  colors: const [AppColors.accent, AppColors.secondary],
                  actionLabel: 'Add',
                  onAction: () => Get.toNamed<void>(AppRoutes.customerAdd),
                ),
                const SizedBox(height: 18),
                Obx(
                  () => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${controller.customers.length} customers',
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
              if (controller.customers.isEmpty) {
                return AppEmptyState(
                  icon: Icons.people_outline_rounded,
                  title: controller.searchQuery.value.isEmpty
                      ? 'No customers yet'
                      : 'No customers found',
                  message: controller.searchQuery.value.isEmpty
                      ? 'Add your first customer to make invoicing faster.'
                      : 'Try a different name, company, mobile or GSTIN.',
                  actionLabel: controller.searchQuery.value.isEmpty
                      ? 'Add customer'
                      : null,
                  onAction: controller.searchQuery.value.isEmpty
                      ? () => Get.toNamed<void>(AppRoutes.customerAdd)
                      : null,
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = ResponsiveUtils.gridColumns(context);
                  final horizontal = ResponsiveUtils.horizontalPadding(context);
                  if (columns == 1) {
                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        4,
                        horizontal,
                        100,
                      ),
                      itemCount: controller.customers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _CustomerCard(
                        customer: controller.customers[index],
                        onDelete: () => _confirmDelete(
                          context,
                          controller.customers[index],
                        ),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      4,
                      horizontal,
                      100,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: ResponsiveUtils.height(context, 156),
                    ),
                    itemCount: controller.customers.length,
                    itemBuilder: (context, index) => _CustomerCard(
                      customer: controller.customers[index],
                      onDelete: () =>
                          _confirmDelete(context, controller.customers[index]),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CustomerModel customer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete customer?'),
        content: Text(
          '${customer.name} will be hidden from customer lists. Historical invoices will remain unchanged.',
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
    if (confirmed ?? false) {
      await controller.deleteCustomer(customer);
    }
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer, required this.onDelete});

  final CustomerModel customer;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      customer.companyName,
      customer.mobile,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' • ');
    return AppCard(
      onTap: () =>
          Get.toNamed<void>(AppRoutes.customerDetails, arguments: customer.id),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              customer.name.characters.first.toUpperCase(),
              style: AppTextStyles.cardTitle.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        customer.name,
                        style: AppTextStyles.cardTitle,
                      ),
                    ),
                    if (customer.gstin != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'GST',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'edit') {
                Get.toNamed<void>(
                  AppRoutes.customerEdit,
                  arguments: customer.id,
                );
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
