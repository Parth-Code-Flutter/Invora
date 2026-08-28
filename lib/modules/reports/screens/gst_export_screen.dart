import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_amount_text.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_bottom_sheet.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_filter_chip.dart';
import '../../../app/widgets/app_grouped_tile.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/gst_export_model.dart';
import '../controllers/gst_export_controller.dart';

class GstExportScreen extends GetView<GstExportController> {
  const GstExportScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const AppBarTitle('GST / CA export'),
      actions: [
        AppBarIconButton(
          tooltip: l10n('Share pack'),
          onPressed: () => controller.exportPack(share: true),
          icon: Icons.ios_share_rounded,
        ),
        AppBarIconButton(
          tooltip: l10n('More'),
          onPressed: () => _showActions(context),
          icon: Icons.more_vert_rounded,
        ),
      ],
    ),
    bottomNavigationBar: Obx(() {
      if (controller.pack.value == null) return const SizedBox.shrink();
      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkBorder
                    : AppColors.border,
              ),
            ),
          ),
          child: AppConstrainedAction(
            maxWidth: ResponsiveUtils.footerMaxWidth(context),
            child: AppButton(
              label: 'Preview PDF',
              icon: Icons.picture_as_pdf_outlined,
              onPressed: () => _previewPdf(context),
            ),
          ),
        ),
      );
    }),
    body: Obx(() {
      if (controller.isLoading.value && controller.pack.value == null) {
        return const Center(child: CircularProgressIndicator());
      }
      final pack = controller.pack.value;
      if (pack == null) {
        return const Center(child: Text('GST export is unavailable.'));
      }
      final tab = controller.registerTab.value;
      return ResponsiveContent(
        tabletMaxWidth: 640,
        largeTabletMaxWidth: 720,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _PeriodCard(
                    controller: controller,
                    onPickFrom: () => _pickDate(context, from: true),
                    onPickTo: () => _pickDate(context, from: false),
                  ),
                  const SizedBox(height: 12),
                  _HeroCard(pack: pack),
                  const SizedBox(height: 12),
                  _TotalsGrid(pack: pack),
                  const SizedBox(height: 18),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _RegisterHeaderDelegate(
                selected: tab,
                pack: pack,
                onSelected: controller.selectRegister,
                background: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
            ..._registerSlivers(pack, tab),
          ],
        ),
      );
    }),
  );

  List<Widget> _registerSlivers(GstExportPack pack, GstExportPreviewTab tab) {
    final rows = <_RowData>[];
    switch (tab) {
      case GstExportPreviewTab.sales:
        for (final row in pack.sales) {
          rows.add(
            _RowData(
              title: row.invoiceNumber,
              subtitle:
                  '${row.customerName}  ·  ${row.supplyType.name.toUpperCase()}',
              caption: _date(row.invoiceDate),
              amountMinor: row.grandTotalMinor,
              onTap: row.invoiceId == null
                  ? null
                  : () => controller.openSource(
                      GstExportSource.invoice,
                      row.invoiceId,
                    ),
            ),
          );
        }
      case GstExportPreviewTab.creditNotes:
        for (final row in pack.creditNotes) {
          rows.add(
            _RowData(
              title: row.creditNoteNumber,
              subtitle: '${row.customerName}  ·  ${row.invoiceNumber}',
              caption: _date(row.creditNoteDate),
              amountMinor: row.grandTotalMinor,
              onTap: row.creditNoteId == null
                  ? null
                  : () => controller.openSource(
                      GstExportSource.creditNote,
                      row.creditNoteId,
                    ),
            ),
          );
        }
      case GstExportPreviewTab.purchases:
        for (final row in pack.purchases) {
          rows.add(
            _RowData(
              title: row.billNumber,
              subtitle: row.supplierName,
              caption: _date(row.billDate),
              amountMinor: row.totalMinor,
              onTap: row.billId == null
                  ? null
                  : () => controller.openSource(
                      GstExportSource.purchase,
                      row.billId,
                    ),
            ),
          );
        }
      case GstExportPreviewTab.debitNotes:
        for (final row in pack.debitNotes) {
          rows.add(
            _RowData(
              title: row.debitNoteNumber,
              subtitle: '${row.supplierName}  ·  ${row.billNumber}',
              caption: _date(row.debitNoteDate),
              amountMinor: row.grandTotalMinor,
              onTap: row.debitNoteId == null
                  ? null
                  : () => controller.openSource(
                      GstExportSource.debitNote,
                      row.debitNoteId,
                    ),
            ),
          );
        }
      case GstExportPreviewTab.hsn:
        for (final row in pack.hsn) {
          rows.add(
            _RowData(
              title: row.hsnSac,
              subtitle: '${row.documentCount} documents',
              caption: 'Tax ${_money(row.taxMinor)}',
              amountMinor: row.totalMinor,
            ),
          );
        }
      case GstExportPreviewTab.exceptions:
        for (final item in pack.exceptions) {
          rows.add(
            _RowData(
              title: item.documentNumber,
              subtitle: item.message,
              caption: _date(item.documentDate),
              trailingLabel: item.kind,
              onTap: () => controller.openSource(item.source, item.documentId),
            ),
          );
        }
    }
    if (rows.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: AppGroupedTile(child: Text(_emptyLabel(tab))),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.only(bottom: 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final row = rows[index];
            return AppGroupedTile(
              position: AppGroupedPositionX.resolve(index, rows.length),
              onTap: row.onTap,
              accentColor: tab == GstExportPreviewTab.exceptions
                  ? AppColors.warning
                  : null,
              child: _RegisterLine(row: row),
            );
          }, childCount: rows.length),
        ),
      ),
    ];
  }

  Future<void> _showActions(BuildContext context) => showAppBottomSheet<void>(
    context: context,
    title: 'Export actions',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionTile(
          icon: Icons.folder_zip_outlined,
          title: 'Save pack',
          subtitle: 'ZIP of CSV registers plus the CA PDF',
          onTap: () {
            Navigator.pop(context);
            controller.exportPack(share: false);
          },
        ),
        _ActionTile(
          icon: Icons.table_view_outlined,
          title: 'Share this register',
          subtitle: 'CSV of the list on this screen',
          onTap: () {
            Navigator.pop(context);
            controller.exportVisibleRegister(share: true);
          },
        ),
        _ActionTile(
          icon: Icons.print_outlined,
          title: 'Print PDF',
          subtitle: 'Send the CA summary to a printer',
          onTap: () {
            Navigator.pop(context);
            controller.printPdf();
          },
        ),
      ],
    ),
  );

  void _previewPdf(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => PdfPreview(
      build: (_) => controller.buildPdf(),
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
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

  static String _emptyLabel(GstExportPreviewTab tab) => switch (tab) {
    GstExportPreviewTab.sales => 'No invoices in this period',
    GstExportPreviewTab.creditNotes => 'No credit notes in this period',
    GstExportPreviewTab.purchases => 'No purchases in this period',
    GstExportPreviewTab.debitNotes => 'No debit notes in this period',
    GstExportPreviewTab.hsn => 'No HSN/SAC lines in this period',
    GstExportPreviewTab.exceptions => 'No exceptions in this period',
  };

  static String _money(int minor) =>
      CurrencyUtils.formatMinor(minor, symbol: '₹');

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _RowData {
  const _RowData({
    required this.title,
    required this.subtitle,
    required this.caption,
    this.amountMinor,
    this.trailingLabel,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String caption;
  final int? amountMinor;
  final String? trailingLabel;
  final VoidCallback? onTap;
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.controller,
    required this.onPickFrom,
    required this.onPickTo,
  });

  final GstExportController controller;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Period', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in GstExportPeriodPreset.values)
                AppFilterChip(
                  label: _presetLabel(value),
                  selected: controller.preset.value == value,
                  onSelected: (_) => controller.applyPreset(value),
                ),
            ],
          ),
          if (controller.preset.value == GstExportPeriodPreset.custom) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: 'From',
                    value: controller.from.value,
                    onTap: onPickFrom,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateButton(
                    label: 'To',
                    value: controller.to.value,
                    onTap: onPickTo,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _presetLabel(GstExportPeriodPreset value) => switch (value) {
    GstExportPeriodPreset.thisMonth => 'This month',
    GstExportPeriodPreset.lastMonth => 'Last month',
    GstExportPeriodPreset.thisFy => 'This FY',
    GstExportPeriodPreset.lastFy => 'Last FY',
    GstExportPeriodPreset.custom => 'Custom',
  };
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.pack});
  final GstExportPack pack;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: .22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pack.period.rangeLabel.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  GstExportPack.filingStatus,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Taxable sales',
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
          AppAmountText(
            amountMinor: pack.summary.taxableSalesMinor,
            symbol: '₹',
            hero: true,
            color: Colors.white,
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 8),
          Text(
            '${pack.summary.invoiceCount} invoices  ·  B2B ${pack.summary.b2bCount}  ·  B2C ${pack.summary.b2cCount}  ·  ${GstExportPack.portalStatus}',
            style: AppTextStyles.secondaryBody.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _TotalsGrid extends StatelessWidget {
  const _TotalsGrid({required this.pack});
  final GstExportPack pack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricWell(
                label: 'Output tax',
                amountMinor: pack.summary.outputTaxMinor,
                color: AppColors.accent,
                fill: AppColors.successLight,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricWell(
                label: 'Credit notes',
                amountMinor: pack.summary.creditNoteTotalMinor,
                color: AppColors.warning,
                fill: AppColors.warningLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricWell(
                label: 'ITC (eligible)',
                amountMinor: pack.summary.itcMinor,
                color: AppColors.success,
                fill: AppColors.successLight,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricWell(
                label: 'Purchases',
                amountMinor: pack.summary.purchaseTotalMinor,
                color: AppColors.secondary,
                fill: AppColors.secondaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricWell extends StatelessWidget {
  const _MetricWell({
    required this.label,
    required this.amountMinor,
    required this.color,
    required this.fill,
  });

  final String label;
  final int amountMinor;
  final Color color;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: .18) : fill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          AppAmountText(
            amountMinor: amountMinor,
            symbol: '₹',
            color: color,
            textAlign: TextAlign.start,
            style: AppTextStyles.listAmount.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _RegisterHeaderDelegate extends SliverPersistentHeaderDelegate {
  _RegisterHeaderDelegate({
    required this.selected,
    required this.pack,
    required this.onSelected,
    required this.background,
  });

  final GstExportPreviewTab selected;
  final GstExportPack pack;
  final ValueChanged<GstExportPreviewTab> onSelected;
  final Color background;

  @override
  double get minExtent => 78;

  @override
  double get maxExtent => 78;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Text(
              'Registers',
              style: AppTextStyles.listName.copyWith(fontSize: 15),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final tab in GstExportPreviewTab.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppFilterChip(
                      label: _tabLabel(tab),
                      count: _tabCount(tab, pack),
                      selected: selected == tab,
                      onSelected: (_) => onSelected(tab),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _RegisterHeaderDelegate oldDelegate) =>
      selected != oldDelegate.selected || pack != oldDelegate.pack;

  static String _tabLabel(GstExportPreviewTab tab) => switch (tab) {
    GstExportPreviewTab.sales => 'Sales',
    GstExportPreviewTab.creditNotes => 'Credit notes',
    GstExportPreviewTab.purchases => 'Purchases',
    GstExportPreviewTab.debitNotes => 'Debit notes',
    GstExportPreviewTab.hsn => 'HSN/SAC',
    GstExportPreviewTab.exceptions => 'Issues',
  };

  static int _tabCount(GstExportPreviewTab tab, GstExportPack pack) =>
      switch (tab) {
        GstExportPreviewTab.sales => pack.summary.invoiceCount,
        GstExportPreviewTab.creditNotes => pack.summary.creditNoteCount,
        GstExportPreviewTab.purchases => pack.summary.purchaseCount,
        GstExportPreviewTab.debitNotes => pack.summary.debitNoteCount,
        GstExportPreviewTab.hsn => pack.hsn.length,
        GstExportPreviewTab.exceptions => pack.summary.exceptionCount,
      };
}

class _RegisterLine extends StatelessWidget {
  const _RegisterLine({required this.row});
  final _RowData row;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.listName,
              ),
              const SizedBox(height: 2),
              Text(
                row.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.small.copyWith(color: muted),
              ),
              const SizedBox(height: 2),
              Text(
                row.caption,
                style: AppTextStyles.caption.copyWith(color: muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (row.amountMinor != null)
          AppAmountColumn(
            children: [
              AppAmountText(amountMinor: row.amountMinor!, symbol: '₹'),
            ],
          )
        else if (row.trailingLabel != null)
          Text(
            row.trailingLabel!,
            style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w700),
          ),
      ],
    );
  }
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.secondary),
      title: Text(title, style: AppTextStyles.listName),
      subtitle: Text(subtitle, style: AppTextStyles.small),
      onTap: onTap,
    );
  }
}
