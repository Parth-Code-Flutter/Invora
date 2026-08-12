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
import '../../../data/models/customer_model.dart';
import '../../../data/models/invoice_model.dart';
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
          Obx(
            () => Padding(
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.horizontalPadding(context),
                ResponsiveUtils.height(context, 8),
                ResponsiveUtils.horizontalPadding(context),
                ResponsiveUtils.height(context, 12),
              ),
              child: _CustomerWorkspaceHeader(
                count: controller.customers.length,
                onAdd: () => Get.toNamed<void>(AppRoutes.customerAdd),
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
                        onInvoice: () => Get.toNamed<void>(
                          AppRoutes.invoiceCreate,
                          arguments: InvoiceEditorArgs(
                            customerId: controller.customers[index].id,
                          ),
                        ),
                        onEdit: () => Get.toNamed<void>(
                          AppRoutes.customerEdit,
                          arguments: controller.customers[index].id,
                        ),
                        onConfirmDelete: () => _confirmDelete(
                          context,
                          controller.customers[index],
                        ),
                        onDelete: () => controller.deleteCustomer(
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
                      onInvoice: () => Get.toNamed<void>(
                        AppRoutes.invoiceCreate,
                        arguments: InvoiceEditorArgs(
                          customerId: controller.customers[index].id,
                        ),
                      ),
                      onEdit: () => Get.toNamed<void>(
                        AppRoutes.customerEdit,
                        arguments: controller.customers[index].id,
                      ),
                      onConfirmDelete: () =>
                          _confirmDelete(context, controller.customers[index]),
                      onDelete: () => controller.deleteCustomer(
                        controller.customers[index],
                      ),
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

  Future<bool> _confirmDelete(
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
    return confirmed ?? false;
  }
}

class _CustomerWorkspaceHeader extends StatelessWidget {
  const _CustomerWorkspaceHeader({required this.count, required this.onAdd});

  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 15, 12, 15),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.secondary, AppColors.primary, AppColors.accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: AppColors.secondary.withValues(alpha: .16),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: .18)),
          ),
          child: const Icon(Icons.people_alt_outlined, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count ${count == 1 ? 'customer' : 'customers'}',
                style: AppTextStyles.cardTitle.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                'Your billing relationships',
                style: AppTextStyles.small.copyWith(
                  color: Colors.white.withValues(alpha: .78),
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
          label: const Text('Add'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.secondary,
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 13),
          ),
        ),
      ],
    ),
  );
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.onInvoice,
    required this.onEdit,
    required this.onConfirmDelete,
    required this.onDelete,
  });

  final CustomerModel customer;
  final VoidCallback onInvoice;
  final VoidCallback onEdit;
  final Future<bool> Function() onConfirmDelete;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      customer.companyName,
      customer.mobile,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' • ');
    return Dismissible(
      key: ValueKey('customer-${customer.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit();
          return false;
        }
        return onConfirmDelete();
      },
      onDismissed: (_) => onDelete(),
      background: const _SwipeActionBackground(
        alignment: Alignment.centerLeft,
        color: AppColors.accent,
        icon: Icons.edit_rounded,
        label: 'Edit',
      ),
      secondaryBackground: const _SwipeActionBackground(
        alignment: Alignment.centerRight,
        color: AppColors.error,
        icon: Icons.delete_outline_rounded,
        label: 'Delete',
      ),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(13, 12, 10, 12),
        onTap: () => Get.toNamed<void>(
          AppRoutes.customerDetails,
          arguments: customer.id,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                customer.name.characters.first.toUpperCase(),
                style: AppTextStyles.sectionTitle.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
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
            IconButton(
              tooltip: 'Create invoice for ${customer.name}',
              onPressed: onInvoice,
              style: IconButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.primaryLight,
              ),
              icon: const Icon(Icons.receipt_long_outlined, size: 20),
            ),
            const SizedBox(width: 3),
            IconButton(
              tooltip: 'Customer actions',
              onPressed: () => _showActions(context),
              icon: const Icon(Icons.more_vert_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(customer.name, style: AppTextStyles.sectionTitle),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Edit customer'),
                subtitle: const Text('Update contact and billing details'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                textColor: AppColors.error,
                iconColor: AppColors.error,
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Delete customer'),
                subtitle: const Text('Invoices already created stay unchanged'),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == 'edit') {
      onEdit();
    } else if (action == 'delete' && await onConfirmDelete()) {
      await onDelete();
    }
  }
}

class _SwipeActionBackground extends StatelessWidget {
  const _SwipeActionBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    alignment: alignment,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (alignment == Alignment.centerRight)
          Text(label, style: const TextStyle(color: Colors.white)),
        if (alignment == Alignment.centerRight) const SizedBox(width: 8),
        Icon(icon, color: Colors.white),
        if (alignment == Alignment.centerLeft) const SizedBox(width: 8),
        if (alignment == Alignment.centerLeft)
          Text(label, style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
}
