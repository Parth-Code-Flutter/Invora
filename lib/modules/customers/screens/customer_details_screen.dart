import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_status_chip.dart';
import '../../../data/models/invoice_model.dart';
import '../../invoices/models/invoice_navigation_args.dart';
import '../controllers/customer_details_controller.dart';

class CustomerDetailsScreen extends GetView<CustomerDetailsController> {
  const CustomerDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Customer details'),
        actions: [
          IconButton(
            tooltip: 'Edit customer',
            onPressed: () async {
              await Get.toNamed<void>(
                AppRoutes.customerEdit,
                arguments: controller.customerId,
              );
              await controller.refreshCustomer();
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          const SizedBox(width: 8),
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
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtils.contentMaxWidth(context),
            ),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.horizontalPadding(context),
                12,
                ResponsiveUtils.horizontalPadding(context),
                32,
              ),
              children: [
                _CustomerHero(
                  name: customer.name,
                  subtitle:
                      customer.companyName ??
                      customer.mobile ??
                      'No contact details',
                ),
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          label: 'Billed',
                          value: CurrencyUtils.formatMinor(
                            controller.billedMinor,
                            symbol: symbol,
                          ),
                        ),
                      ),
                      const _MetricDivider(),
                      Expanded(
                        child: _Metric(
                          label: 'Paid',
                          value: CurrencyUtils.formatMinor(
                            controller.paidMinor,
                            symbol: symbol,
                          ),
                          color: AppColors.success,
                        ),
                      ),
                      const _MetricDivider(),
                      Expanded(
                        child: _Metric(
                          label: 'Due',
                          value: CurrencyUtils.formatMinor(
                            controller.outstandingMinor,
                            symbol: symbol,
                          ),
                          color: controller.outstandingMinor > 0
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Contact & billing', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 9),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  child: Column(
                    children: [
                      _InfoTile(
                        icon: Icons.phone_outlined,
                        label: 'Mobile',
                        value: customer.mobile,
                      ),
                      _InfoTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: customer.email,
                      ),
                      _InfoTile(
                        icon: Icons.location_on_outlined,
                        label: 'Billing address',
                        value: [
                          customer.address,
                          customer.city,
                          customer.state,
                          customer.pinCode,
                        ].whereType<String>().join(', '),
                      ),
                      _InfoTile(
                        icon: Icons.business_outlined,
                        label: 'Company',
                        value: customer.companyName,
                      ),
                      _InfoTile(
                        icon: Icons.receipt_long_outlined,
                        label: 'GSTIN',
                        value: customer.gstin,
                      ),
                      _InfoTile(
                        icon: Icons.notes_rounded,
                        label: 'Notes',
                        value: customer.notes,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invoice history',
                            style: AppTextStyles.sectionTitle,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${controller.invoices.length} ${controller.invoices.length == 1 ? 'invoice' : 'invoices'} • Read-only with PDF access',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => Get.toNamed<void>(
                        AppRoutes.invoiceCreate,
                        arguments: InvoiceEditorArgs(customerId: customer.id),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('New'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (controller.invoices.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          color: AppColors.primary,
                          size: 30,
                        ),
                        const SizedBox(height: 8),
                        Text('No invoices yet', style: AppTextStyles.cardTitle),
                        const SizedBox(height: 3),
                        Text(
                          'Create the first invoice for this customer.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...controller.invoices.map(
                    (invoice) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _InvoiceHistoryTile(
                        invoice: invoice,
                        symbol: symbol,
                        onTap: () => Get.toNamed<void>(
                          AppRoutes.invoiceDetails,
                          arguments: InvoiceDetailsArgs(
                            invoiceId: invoice.id,
                            readOnly: true,
                          ),
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

class _CustomerHero extends StatelessWidget {
  const _CustomerHero({required this.name, required this.subtitle});

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.secondary, AppColors.primary, Color(0xFF2DAFA3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: AppColors.secondary.withValues(alpha: .18),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 58,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: .18)),
          ),
          child: Text(
            name.trim().isEmpty ? '?' : name.characters.first.toUpperCase(),
            style: AppTextStyles.pageTitle.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CUSTOMER ACCOUNT',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(alpha: .76),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.pageTitle.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  color: Colors.white.withValues(alpha: .84),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.cardTitle.copyWith(color: color),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        maxLines: 1,
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
    ],
  );
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 34, color: AppColors.border);
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value!, style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceHistoryTile extends StatelessWidget {
  const _InvoiceHistoryTile({
    required this.invoice,
    required this.symbol,
    required this.onTap,
  });

  final InvoiceSummaryModel invoice;
  final String symbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = invoice.effectiveStatus(DateTime.now());
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invoice.invoiceNumber, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      'Issued ${_date(invoice.invoiceDate)}',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AppStatusChip(status: status),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Text(
                CurrencyUtils.formatMinor(
                  invoice.grandTotalMinor,
                  symbol: symbol,
                ),
                style: AppTextStyles.cardTitle,
              ),
              if (invoice.balanceMinor > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '${CurrencyUtils.formatMinor(invoice.balanceMinor, symbol: symbol)} due',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const Spacer(),
              const Icon(
                Icons.picture_as_pdf_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                'View & export',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
