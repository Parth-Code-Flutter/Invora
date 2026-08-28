import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_amount_text.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_invoice_summary_card.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/cash_book_models.dart';
import '../controllers/customer_details_controller.dart';

class CustomerDetailsScreen extends GetView<CustomerDetailsController> {
  const CustomerDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Obx(() {
          final name = controller.customer.value?.name.trim();
          if (name == null || name.isEmpty) {
            return const AppBarTitle('Customer details');
          }
          return AppBarTitle(name, subtitle: 'Customer');
        }),
        actions: [
          AppBarIconButton(
            tooltip: l10n('Edit customer'),
            onPressed: () async {
              await Get.toNamed<void>(
                AppRoutes.customerEdit,
                arguments: controller.customerId,
              );
              await controller.refreshCustomer();
            },
            icon: Icons.edit_outlined,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final customer = controller.customer.value;
        if (customer == null) {
          return const Center(child: Text('Customer not found.'));
        }
        final symbol = controller.currencySymbol.value;
        final hasDue = controller.outstandingMinor > 0;
        final billed = controller.billedMinor;
        final company = customer.companyName?.trim();
        final heroContact = [
          if (company != null && company.isNotEmpty) company,
          if (controller.invoices.isNotEmpty)
            '${controller.invoices.length} ${controller.invoices.length == 1 ? 'invoice' : 'invoices'}',
        ].join(' • ');
        final infoRows = _contactRows(
          customer,
          hideCompany: company != null && company.isNotEmpty,
        );
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtils.isTablet(context) ? 820 : 680,
            ),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.horizontalPadding(context),
                8,
                ResponsiveUtils.horizontalPadding(context),
                16,
              ),
              children: [
                _CustomerHero(
                  name: customer.name,
                  contact: heroContact,
                  billedMinor: billed,
                  paidMinor: controller.paidMinor,
                  dueMinor: controller.outstandingMinor,
                  symbol: symbol,
                  hasDue: hasDue,
                  hasOverdue: controller.hasOverdue,
                ),
                const SizedBox(height: 10),
                AppConstrainedAction(
                  child: AppButton(
                    label: controller.invoices.isEmpty
                        ? 'New invoice'
                        : hasDue
                        ? 'Collect outstanding'
                        : 'View customer statement',
                    icon: controller.invoices.isEmpty
                        ? Icons.add_rounded
                        : Icons.account_balance_wallet_outlined,
                    onPressed: () {
                      if (controller.invoices.isEmpty) {
                        Get.toNamed<void>(
                          AppRoutes.invoiceCreate,
                          arguments: InvoiceEditorArgs(customerId: customer.id),
                        );
                        return;
                      }
                      Get.toNamed<void>(
                        AppRoutes.customerStatement,
                        arguments: customer.id,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () => Get.toNamed<void>(
                      AppRoutes.cashBookAdvance,
                      arguments: CashBookAdvanceArgs(
                        partyType: PartyKind.customer,
                        partyId: customer.id,
                        partyName: customer.name,
                      ),
                    ),
                    icon: const Icon(Icons.savings_outlined, size: 18),
                    label: const Text('Record customer advance'),
                  ),
                ),
                if (infoRows.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Contact & billing',
                    style: AppTextStyles.listName.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    child: Column(
                      children: [
                        for (final (index, row) in infoRows.indexed) ...[
                          _InfoTile(
                            icon: row.icon,
                            label: row.label,
                            value: row.value,
                          ),
                          if (index != infoRows.length - 1)
                            const Divider(height: 1, indent: 26),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invoice history',
                            style: AppTextStyles.listName.copyWith(
                              fontSize: 15,
                            ),
                          ),
                          if (controller.invoices.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${controller.invoices.length} ${controller.invoices.length == 1 ? 'invoice' : 'invoices'}',
                              style: AppTextStyles.caption.copyWith(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (controller.invoices.isNotEmpty)
                      FilledButton.tonalIcon(
                        onPressed: () => Get.toNamed<void>(
                          AppRoutes.invoiceCreate,
                          arguments: InvoiceEditorArgs(customerId: customer.id),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('New invoice'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          textStyle: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (controller.invoices.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          color: AppColors.primary,
                          size: 26,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No invoices yet',
                          style: AppTextStyles.listName.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Create the first invoice for this customer.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...controller.invoices.map(
                    (invoice) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppInvoiceSummaryCard(
                        invoice: invoice,
                        currencySymbol: symbol,
                        showCustomer: false,
                        onTap: () => Get.toNamed<void>(
                          AppRoutes.invoiceDetails,
                          arguments: invoice.id,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

List<({IconData icon, String label, String value})> _contactRows(
  CustomerModel customer, {
  required bool hideCompany,
}) {
  final address = [
    customer.address,
    customer.city,
    customer.state,
    customer.pinCode,
  ].where((part) => part?.trim().isNotEmpty ?? false).join(', ');
  return <({IconData icon, String label, String? value})>[
        (icon: Icons.phone_outlined, label: 'Mobile', value: customer.mobile),
        (icon: Icons.email_outlined, label: 'Email', value: customer.email),
        (
          icon: Icons.location_on_outlined,
          label: 'Billing address',
          value: address,
        ),
        if (!hideCompany)
          (
            icon: Icons.business_outlined,
            label: 'Company',
            value: customer.companyName,
          ),
        (
          icon: Icons.receipt_long_outlined,
          label: 'GSTIN',
          value: customer.gstin,
        ),
        (icon: Icons.notes_rounded, label: 'Notes', value: customer.notes),
      ]
      .where((row) => row.value?.trim().isNotEmpty ?? false)
      .map(
        (row) => (icon: row.icon, label: row.label, value: row.value!.trim()),
      )
      .toList();
}

class _CustomerHero extends StatelessWidget {
  const _CustomerHero({
    required this.name,
    required this.contact,
    required this.billedMinor,
    required this.paidMinor,
    required this.dueMinor,
    required this.symbol,
    required this.hasDue,
    required this.hasOverdue,
  });

  final String name;
  final String contact;
  final int billedMinor;
  final int paidMinor;
  final int dueMinor;
  final String symbol;
  final bool hasDue;
  final bool hasOverdue;

  List<Color> get _colors {
    if (hasOverdue) return const [AppColors.secondary, AppColors.error];
    if (hasDue) return const [AppColors.secondary, AppColors.warning];
    if (billedMinor > 0) return const [AppColors.secondary, AppColors.success];
    return const [AppColors.secondary, AppColors.primary];
  }

  String? get _statusLabel {
    if (hasDue) return 'Outstanding';
    if (billedMinor > 0) return 'Paid in full';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    final statusLabel = _statusLabel;
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .14)),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: .2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -40,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .1),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .2),
                      ),
                    ),
                    child: Text(
                      _initials(name),
                      style: AppTextStyles.listName.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: contact.isEmpty
                        ? const SizedBox.shrink()
                        : Text(
                            contact,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: .84),
                              fontSize: 12,
                            ),
                          ),
                  ),
                  if (statusLabel != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        statusLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Container(height: 1, color: Colors.white.withValues(alpha: .18)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _HeroMetric(
                      label: 'Billed',
                      amountMinor: billedMinor,
                      symbol: symbol,
                    ),
                  ),
                  const _HeroMetricDivider(),
                  Expanded(
                    child: _HeroMetric(
                      label: 'Paid',
                      amountMinor: paidMinor,
                      symbol: symbol,
                      color: const Color(0xFFA8F3D5),
                    ),
                  ),
                  const _HeroMetricDivider(),
                  Expanded(
                    child: _HeroMetric(
                      label: 'Due',
                      amountMinor: dueMinor,
                      symbol: symbol,
                      emphasized: true,
                      color: hasDue
                          ? const Color(0xFFFFD99A)
                          : const Color(0xFFA8F3D5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.amountMinor,
    required this.symbol,
    this.color,
    this.emphasized = false,
  });

  final String label;
  final int amountMinor;
  final String symbol;
  final Color? color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppAmountText(
        amountMinor: amountMinor,
        symbol: symbol,
        textAlign: TextAlign.center,
        color: color ?? Colors.white,
        style: AppTextStyles.listAmount.copyWith(
          color: color ?? Colors.white,
          fontSize: emphasized ? 15 : 13,
          fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        maxLines: 1,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white.withValues(alpha: .72),
          fontSize: 10,
        ),
      ),
    ],
  );
}

class _HeroMetricDivider extends StatelessWidget {
  const _HeroMetricDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 28,
    color: Colors.white.withValues(alpha: .18),
  );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: secondary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: AppTextStyles.listName.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}
