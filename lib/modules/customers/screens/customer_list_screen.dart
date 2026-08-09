import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../data/models/customer_model.dart';
import '../controllers/customer_list_controller.dart';

class CustomerListScreen extends GetView<CustomerListController> {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed<void>(AppRoutes.customerAdd),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add customer'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              onChanged: controller.updateSearch,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search name, company, mobile or GSTIN',
                prefixIcon: Icon(Icons.search_rounded),
              ),
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
                  final columns = constraints.maxWidth >= 900
                      ? 3
                      : constraints.maxWidth >= 600
                      ? 2
                      : 1;
                  if (columns == 1) {
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
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
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 156,
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
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryLight,
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
                Text(customer.name, style: AppTextStyles.cardTitle),
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
                if (customer.gstin != null) ...[
                  const SizedBox(height: 6),
                  Text('GSTIN ${customer.gstin}', style: AppTextStyles.small),
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
