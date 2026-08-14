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
import '../widgets/customer_list_overview.dart';

class CustomerListScreen extends GetView<CustomerListController> {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppSearchAppBar(
        title: 'Customers',
        titleSuffix: Obx(
          () => Text(
            '(${controller.totalCustomerCount.value})',
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
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
        final due = controller.customers
            .where((customer) => controller.balanceFor(customer) > 0)
            .toList();
        final allOthers = controller.customers
            .where((customer) => controller.balanceFor(customer) == 0)
            .toList();
        final horizontal = ResponsiveUtils.horizontalPadding(context);
        return ListView(
          padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 100),
          children: [
            CustomerListOverview(
              totalCustomers: controller.totalCustomerCount.value,
              amountDueMinor: controller.totalAmountDueMinor,
              dueCustomers: controller.dueCustomerCount,
              paidAmountMinor: controller.totalPaidAmountMinor,
              paidCustomers: controller.paidCustomerCount,
              currencySymbol: controller.currencySymbol.value,
            ),
            if (due.isNotEmpty) ...[
              const SizedBox(height: 22),
              _CustomerSection(
                title: 'Needs attention',
                count: due.length,
                attention: true,
                customers: due,
                cardBuilder: (customer, index) =>
                    _customerCard(context, customer, index),
              ),
            ],
            if (allOthers.isNotEmpty) ...[
              const SizedBox(height: 22),
              _CustomerSection(
                title: 'All customers',
                count: allOthers.length,
                customers: allOthers,
                cardBuilder: (customer, index) =>
                    _customerCard(context, customer, due.length + index),
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _customerCard(
    BuildContext context,
    CustomerModel customer,
    int index,
  ) => AppListEntrance(
    index: index,
    child: CustomerSummaryCard(
      customer: customer,
      billedMinor: controller.billedFor(customer),
      balanceMinor: controller.balanceFor(customer),
      invoiceCount: controller.invoiceCountFor(customer),
      currencySymbol: controller.currencySymbol.value,
      onInvoice: () => Get.toNamed<void>(
        AppRoutes.invoiceCreate,
        arguments: InvoiceEditorArgs(customerId: customer.id),
      ),
      onEdit: () =>
          Get.toNamed<void>(AppRoutes.customerEdit, arguments: customer.id),
      onConfirmDelete: () => _confirmDelete(context, customer),
      onDelete: () => controller.deleteCustomer(customer),
    ),
  );

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

class _CustomerSection extends StatelessWidget {
  const _CustomerSection({
    required this.title,
    required this.count,
    required this.customers,
    required this.cardBuilder,
    this.attention = false,
  });

  final String title;
  final int count;
  final List<CustomerModel> customers;
  final Widget Function(CustomerModel customer, int index) cardBuilder;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (attention) ...[
              const Icon(
                Icons.error_outline_rounded,
                size: 16,
                color: AppColors.error,
              ),
              const SizedBox(width: 7),
            ],
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
              ),
            ),
            Text(
              '$count ${count == 1 ? 'customer' : 'customers'}',
              style: AppTextStyles.caption.copyWith(color: secondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = ResponsiveUtils.gridColumns(context);
            const gap = 10.0;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var index = 0; index < customers.length; index++)
                  SizedBox(
                    width: width,
                    child: cardBuilder(customers[index], index),
                  ),
              ],
            );
          },
        ),
      ],
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
    final mobile = customer.mobile?.trim() ?? '';
    final company = customer.companyName?.trim() ?? '';
    final contact = mobile.isNotEmpty ? mobile : company;
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
      child: GestureDetector(
        onLongPress: () => _showActions(context),
        child: AppGroupedTile(
          position: position,
          accentColor: statusColor,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          onTap: () => Get.toNamed<void>(
            AppRoutes.customerDetails,
            arguments: customer.id,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.22 : 0.11),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  customer.name.characters.first.toUpperCase(),
                  style: AppTextStyles.listName.copyWith(
                    color: statusColor,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                      Row(
                        children: [
                          Icon(
                            mobile.isNotEmpty
                                ? Icons.phone_outlined
                                : Icons.business_outlined,
                            size: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              contact,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 11,
                          color: statusColor,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            invoiceCount == 0
                                ? 'Ready to invoice'
                                : balanceMinor > 0
                                ? '$invoiceCount ${invoiceCount == 1 ? 'invoice' : 'invoices'} due'
                                : '$invoiceCount ${invoiceCount == 1 ? 'invoice' : 'invoices'} settled',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppAmountColumn(
                maxWidth: 120,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(
                          alpha: isDark ? 0.22 : 0.11,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  AppAmountText(
                    amountMinor: balanceMinor > 0 ? balanceMinor : billedMinor,
                    symbol: currencySymbol,
                    textAlign: TextAlign.end,
                    color: balanceMinor == 0 && invoiceCount > 0
                        ? (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textTertiary)
                        : null,
                    style: AppTextStyles.listAmount,
                  ),
                ],
              ),
            ],
          ),
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
