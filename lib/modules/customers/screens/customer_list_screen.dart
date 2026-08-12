import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_dialog.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_search_app_bar.dart';
import '../../../app/widgets/app_main_navigation.dart';
import '../../../app/widgets/app_list_motion.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/invoice_model.dart';
import '../controllers/customer_list_controller.dart';

class CustomerListScreen extends GetView<CustomerListController> {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Add customer',
        onPressed: () => Get.toNamed<void>(AppRoutes.customerAdd),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Customer'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppSearchAppBar(
        title: 'Customers',
        hint: 'Name, mobile or GSTIN',
        onChanged: controller.updateSearch,
      ),
      bottomNavigationBar: const AppMainNavigation(
        current: MainDestination.customers,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppListSkeleton();
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
                padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 100),
                itemCount: controller.customers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => AppListEntrance(
                  index: index,
                  child: _CustomerCard(
                    customer: controller.customers[index],
                    billedMinor: controller.billedFor(
                      controller.customers[index],
                    ),
                    balanceMinor: controller.balanceFor(
                      controller.customers[index],
                    ),
                    invoiceCount: controller.invoiceCountFor(
                      controller.customers[index],
                    ),
                    currencySymbol: controller.currencySymbol.value,
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
                    onDelete: () =>
                        controller.deleteCustomer(controller.customers[index]),
                  ),
                ),
              );
            }
            return GridView.builder(
              padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 100),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: ResponsiveUtils.height(context, 156),
              ),
              itemCount: controller.customers.length,
              itemBuilder: (context, index) => AppListEntrance(
                index: index,
                child: _CustomerCard(
                  customer: controller.customers[index],
                  billedMinor: controller.billedFor(
                    controller.customers[index],
                  ),
                  balanceMinor: controller.balanceFor(
                    controller.customers[index],
                  ),
                  invoiceCount: controller.invoiceCountFor(
                    controller.customers[index],
                  ),
                  currencySymbol: controller.currencySymbol.value,
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
                  onDelete: () =>
                      controller.deleteCustomer(controller.customers[index]),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    CustomerModel customer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        icon: Icons.person_remove_outlined,
        iconColor: AppColors.error,
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

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.onInvoice,
    required this.onEdit,
    required this.onConfirmDelete,
    required this.onDelete,
    required this.billedMinor,
    required this.balanceMinor,
    required this.invoiceCount,
    required this.currencySymbol,
  });

  final CustomerModel customer;
  final VoidCallback onInvoice;
  final VoidCallback onEdit;
  final Future<bool> Function() onConfirmDelete;
  final Future<void> Function() onDelete;
  final int billedMinor;
  final int balanceMinor;
  final int invoiceCount;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final contact = [
      customer.companyName,
      customer.mobile,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' • ');
    final created = _createdLabel(customer.createdAt);
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
        padding: const EdgeInsets.fromLTRB(13, 11, 7, 11),
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
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    created,
                    maxLines: 1,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  if (contact.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      contact,
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
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  CurrencyUtils.formatMinor(
                    billedMinor,
                    symbol: currencySymbol,
                  ),
                  style: AppTextStyles.cardTitle.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      invoiceCount == 0
                          ? 'No invoices'
                          : balanceMinor > 0
                          ? 'Due'
                          : 'Paid',
                      style: AppTextStyles.caption.copyWith(
                        color: balanceMinor > 0
                            ? AppColors.warning
                            : invoiceCount == 0
                            ? AppColors.textTertiary
                            : AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: balanceMinor > 0
                            ? AppColors.warning
                            : invoiceCount == 0
                            ? AppColors.textTertiary
                            : AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Create invoice'),
                subtitle: const Text('Start with this customer selected'),
                onTap: () => Navigator.pop(context, 'invoice'),
              ),
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
    if (action == 'invoice') {
      onInvoice();
    } else if (action == 'edit') {
      onEdit();
    } else if (action == 'delete' && await onConfirmDelete()) {
      await onDelete();
    }
  }

  static String _createdLabel(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Created ${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]} ${value.year}';
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
