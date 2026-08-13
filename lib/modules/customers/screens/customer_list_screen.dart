import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_amount_text.dart';
import '../../../app/widgets/app_dialog.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_grouped_tile.dart';
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
                  child: CustomerSummaryCard(
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
                mainAxisExtent: ResponsiveUtils.height(context, 96),
              ),
              itemCount: controller.customers.length,
              itemBuilder: (context, index) => AppListEntrance(
                index: index,
                child: CustomerSummaryCard(
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
    return showAppConfirmDialog(
      context: context,
      destructive: true,
      icon: Icons.person_remove_outlined,
      title: 'Delete customer?',
      message:
          '${customer.name} will be hidden from customer lists. Historical invoices will remain unchanged.',
      confirmLabel: 'Delete',
    );
  }
}

class CustomerSummaryCard extends StatelessWidget {
  const CustomerSummaryCard({
    required this.customer,
    required this.onInvoice,
    required this.onEdit,
    required this.onConfirmDelete,
    required this.onDelete,
    required this.billedMinor,
    required this.balanceMinor,
    required this.invoiceCount,
    required this.currencySymbol,
    this.position = AppGroupedPosition.single,
    super.key,
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
  final AppGroupedPosition position;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contact = [
      customer.companyName,
      customer.mobile,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' • ');
    final statusLabel = invoiceCount == 0
        ? 'No invoices'
        : balanceMinor > 0
        ? 'Due'
        : 'Paid';
    final statusColor = balanceMinor > 0
        ? AppColors.warning
        : invoiceCount == 0
        ? AppColors.textTertiary
        : AppColors.success;
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
      child: AppGroupedTile(
        position: position,
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        onTap: () => Get.toNamed<void>(
          AppRoutes.customerDetails,
          arguments: customer.id,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final amountMax = (constraints.maxWidth * 0.36).clamp(80.0, 140.0);
            return Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    customer.name.characters.first.toUpperCase(),
                    style: AppTextStyles.listName.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.listName,
                      ),
                      if (contact.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          contact,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AppAmountColumn(
                  maxWidth: amountMax,
                  children: [
                    AppAmountText(
                      amountMinor: billedMinor,
                      symbol: currencySymbol,
                      color: balanceMinor == 0 && invoiceCount > 0
                          ? (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textTertiary)
                          : null,
                      style: AppTextStyles.listAmount,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      statusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: AppTextStyles.caption.copyWith(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Customer actions',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  onPressed: () => _showActions(context),
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                ),
              ],
            );
          },
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
