import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_entity_header.dart';
import '../../../app/widgets/app_status_chip.dart';
import '../../../data/models/invoice_model.dart';
import '../controllers/customer_details_controller.dart';

class CustomerDetailsScreen extends GetView<CustomerDetailsController> {
  const CustomerDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.horizontalPadding(context),
            vertical: ResponsiveUtils.height(context, 20),
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveUtils.contentMaxWidth(context),
                ),
                child: Column(
                  children: [
                    AppEntityHeader(
                      icon: Text(customer.name.characters.first.toUpperCase()),
                      title: customer.name,
                      subtitle: customer.companyName ?? customer.mobile,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            label: 'Total invoices',
                            value: '${controller.invoices.length}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            label: 'Outstanding',
                            value: CurrencyUtils.formatMinor(
                              controller.outstandingMinor,
                              symbol: controller.currencySymbol.value,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer information',
                            style: AppTextStyles.sectionTitle,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Mobile',
                            value: customer.mobile,
                          ),
                          _InfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: customer.email,
                          ),
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Address',
                            value: [
                              customer.address,
                              customer.city,
                              customer.state,
                              customer.pinCode,
                            ].whereType<String>().join(', '),
                          ),
                          _InfoRow(
                            icon: Icons.receipt_long_outlined,
                            label: 'GSTIN',
                            value: customer.gstin,
                          ),
                          _InfoRow(
                            icon: Icons.notes_rounded,
                            label: 'Notes',
                            value: customer.notes,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Recent invoices',
                            style: AppTextStyles.sectionTitle,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => Get.toNamed<void>(
                            AppRoutes.invoiceCreate,
                            arguments: InvoiceEditorArgs(
                              customerId: customer.id,
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Create invoice'),
                        ),
                      ],
                    ),
                    if (controller.invoices.isEmpty)
                      const AppCard(
                        child: ListTile(
                          leading: Icon(Icons.receipt_long_outlined),
                          title: Text('No invoices yet'),
                          subtitle: Text(
                            'Create this customer’s first invoice.',
                          ),
                        ),
                      )
                    else
                      ...controller.invoices
                          .take(5)
                          .map(
                            (invoice) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: AppCard(
                                onTap: () => Get.toNamed<void>(
                                  AppRoutes.invoiceDetails,
                                  arguments: invoice.id,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            invoice.invoiceNumber,
                                            style: AppTextStyles.cardTitle,
                                          ),
                                          Text(
                                            CurrencyUtils.formatMinor(
                                              invoice.grandTotalMinor,
                                              symbol: controller
                                                  .currencySymbol
                                                  .value,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AppStatusChip(
                                      status: invoice.effectiveStatus(
                                        DateTime.now(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Text(value, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.small),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          SizedBox(width: 72, child: Text(label, style: AppTextStyles.small)),
          Expanded(child: Text(value!, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
