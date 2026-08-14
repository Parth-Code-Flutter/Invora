import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/services/data_export_service.dart';
import '../controllers/data_export_controller.dart';

class DataExportScreen extends GetView<DataExportController> {
  const DataExportScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Export data'),
    ),
    body: ResponsiveContent(
      tabletMaxWidth: 760,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: .65),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.table_view_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Export portable CSV files for spreadsheets or a printable sales report. Amounts use decimal major units and dates use YYYY-MM-DD.',
                    style: AppTextStyles.secondaryBody,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial date range',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Used for invoices, payments, and reports.',
                    style: AppTextStyles.secondaryBody,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DateButton(
                          label: 'From',
                          value: controller.from.value,
                          onTap: () => _pickDate(context, from: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DateButton(
                          label: 'To',
                          value: controller.to.value,
                          onTap: () => _pickDate(context, from: false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('BUSINESS DATA', style: AppTextStyles.small),
          const SizedBox(height: 8),
          _ExportTile(
            type: DataExportType.customers,
            icon: Icons.people_alt_outlined,
            title: 'Customers',
            subtitle: 'Contact, billing, GSTIN and notes',
            controller: controller,
          ),
          const SizedBox(height: 10),
          _ExportTile(
            type: DataExportType.products,
            icon: Icons.inventory_2_outlined,
            title: 'Products & services',
            subtitle: 'Price, unit, HSN/SAC and GST rate',
            controller: controller,
          ),
          const SizedBox(height: 18),
          Text('FINANCIAL DATA', style: AppTextStyles.small),
          const SizedBox(height: 8),
          _ExportTile(
            type: DataExportType.invoices,
            icon: Icons.receipt_long_outlined,
            title: 'Invoices',
            subtitle: 'Customer, tax breakdown, totals and status',
            controller: controller,
          ),
          const SizedBox(height: 10),
          _ExportTile(
            type: DataExportType.payments,
            icon: Icons.payments_outlined,
            title: 'Payment ledger',
            subtitle: 'Payments, reversals, methods and references',
            controller: controller,
          ),
          const SizedBox(height: 10),
          _ReportTile(controller: controller),
        ],
      ),
    ),
  );

  Future<void> _pickDate(BuildContext context, {required bool from}) async {
    final current = from ? controller.from.value : controller.to.value;
    final result = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (result == null) return;
    if (from) {
      controller.setFrom(result);
    } else {
      controller.setTo(result);
    }
  }
}

class _ExportTile extends StatelessWidget {
  const _ExportTile({
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.controller,
  });

  final DataExportType type;
  final IconData icon;
  final String title;
  final String subtitle;
  final DataExportController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final busy = controller.busyExport.value == type;
    final disabled =
        controller.busyExport.value != null || controller.isBuildingPdf.value;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.small),
              ],
            ),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            IconButton(
              tooltip: l10n('Share CSV'),
              onPressed: disabled
                  ? null
                  : () => controller.exportCsv(type, share: true),
              icon: const Icon(Icons.ios_share_rounded),
            ),
            IconButton(
              tooltip: l10n('Save CSV'),
              onPressed: disabled
                  ? null
                  : () => controller.exportCsv(type, share: false),
              icon: const Icon(Icons.download_rounded),
            ),
          ],
        ],
      ),
    );
  });
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.controller});
  final DataExportController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final disabled =
        controller.busyExport.value != null || controller.isBuildingPdf.value;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.assessment_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sales report', style: AppTextStyles.cardTitle),
                    Text(
                      'Period totals and invoice activity',
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: disabled
                      ? null
                      : () => controller.exportCsv(
                          DataExportType.report,
                          share: false,
                        ),
                  icon: const Icon(Icons.table_view_outlined),
                  label: const Text('Save CSV'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: disabled
                      ? null
                      : () => controller.exportReportPdf(share: true),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(
                    controller.isBuildingPdf.value ? 'Building…' : 'Share PDF',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  });
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      alignment: Alignment.centerLeft,
    ),
    child: Row(
      children: [
        const Icon(Icons.calendar_today_outlined, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              Text(_date(value), maxLines: 1),
            ],
          ),
        ),
      ],
    ),
  );

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
