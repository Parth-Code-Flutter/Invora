import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/quantity_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_bottom_sheet.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_empty_state.dart';
import '../../../app/widgets/app_filter_chip.dart';
import '../../../app/widgets/app_grouped_tile.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/gst_export_model.dart';
import '../../../data/models/stock_models.dart';
import '../../../data/models/stock_report_model.dart';
import '../controllers/stock_report_controller.dart';

class StockReportScreen extends GetView<StockReportController> {
  const StockReportScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const AppBarTitle('Stock reports'),
      actions: [
        AppBarIconButton(
          tooltip: l10n('Share CSV'),
          onPressed: () => controller.exportCsv(share: true),
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
      final pack = controller.pack.value;
      if (pack == null || !pack.enabled) return const SizedBox.shrink();
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
        return const Center(child: Text('Stock report is unavailable.'));
      }
      if (!pack.enabled) {
        return AppEmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Stock tracking off',
          message: 'Keep stock for a product to use these reports.',
          actionLabel: 'Create product',
          onAction: controller.openAddProduct,
        );
      }
      final kind = controller.kind.value;
      return ResponsiveContent(
        tabletMaxWidth: 640,
        largeTabletMaxWidth: 720,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _KindTabs(
                    kind: kind,
                    onHandCount: pack.kind == StockReportKind.onHand
                        ? pack.productCount
                        : null,
                    movementCount: pack.kind == StockReportKind.movements
                        ? pack.movements.length
                        : null,
                    onSelected: controller.selectKind,
                  ),
                  const SizedBox(height: 12),
                  if (kind == StockReportKind.onHand)
                    _AsOfCard(
                      asOf: controller.asOf.value,
                      onPick: () => _pickAsOf(context),
                    )
                  else
                    _PeriodCard(
                      controller: controller,
                      onPickFrom: () => _pickRange(context, from: true),
                      onPickTo: () => _pickRange(context, from: false),
                    ),
                  const SizedBox(height: 12),
                  _HeroCard(pack: pack),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Quantities use when stock was posted, not the invoice date.',
                      style: AppTextStyles.caption.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecondary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            if (kind == StockReportKind.onHand)
              ..._onHandSlivers(pack)
            else
              ..._movementSlivers(pack),
          ],
        ),
      );
    }),
  );

  List<Widget> _onHandSlivers(StockReportPack pack) {
    if (pack.onHand.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: AppGroupedTile(child: Text('No products to show')),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.only(bottom: 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final row = pack.onHand[index];
            return AppGroupedTile(
              position: AppGroupedPositionX.resolve(index, pack.onHand.length),
              onTap: () => Get.toNamed<void>(
                AppRoutes.productDetails,
                arguments: row.productId,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.name, style: AppTextStyles.listName),
                        const SizedBox(height: 2),
                        Text(row.unit, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  Text(
                    row.quantityLabel,
                    style: AppTextStyles.listAmount.copyWith(
                      color: row.quantityScaled < 0
                          ? AppColors.error
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }, childCount: pack.onHand.length),
        ),
      ),
    ];
  }

  List<Widget> _movementSlivers(StockReportPack pack) {
    if (pack.movements.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: AppGroupedTile(child: Text('No movements in this period')),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.only(bottom: 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final row = pack.movements[index];
            return AppGroupedTile(
              position: AppGroupedPositionX.resolve(
                index,
                pack.movements.length,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.productName, style: AppTextStyles.listName),
                        const SizedBox(height: 2),
                        Text(
                          [
                            row.type.label,
                            row.source.label,
                            if (row.movement.reason?.trim().isNotEmpty ?? false)
                              row.movement.reason!.trim(),
                            StockDay.displayDateTime(row.movement.createdAt),
                          ].join(' · '),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${row.quantityLabel} ${row.unit}',
                    style: AppTextStyles.listAmount.copyWith(
                      color: row.movement.quantityScaled < 0
                          ? AppColors.error
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }, childCount: pack.movements.length),
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
          icon: Icons.save_alt_outlined,
          title: 'Save CSV',
          subtitle: 'Spreadsheet of the list on this screen',
          onTap: () {
            Navigator.pop(context);
            controller.exportCsv(share: false);
          },
        ),
        _ActionTile(
          icon: Icons.picture_as_pdf_outlined,
          title: 'Share PDF',
          subtitle: 'Printable copy of this report',
          onTap: () {
            Navigator.pop(context);
            controller.exportPdf(share: true);
          },
        ),
        _ActionTile(
          icon: Icons.print_outlined,
          title: 'Print PDF',
          subtitle: 'Send this report to a printer',
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

  Future<void> _pickAsOf(BuildContext context) async {
    final result = await showDatePicker(
      context: context,
      initialDate: controller.asOf.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (result == null) return;
    controller.setAsOf(result);
  }

  Future<void> _pickRange(BuildContext context, {required bool from}) async {
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

class _KindTabs extends StatelessWidget {
  const _KindTabs({
    required this.kind,
    required this.onSelected,
    this.onHandCount,
    this.movementCount,
  });

  final StockReportKind kind;
  final ValueChanged<StockReportKind> onSelected;
  final int? onHandCount;
  final int? movementCount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          AppFilterChip(
            label: 'On hand as of',
            count: onHandCount,
            selected: kind == StockReportKind.onHand,
            onSelected: (_) => onSelected(StockReportKind.onHand),
          ),
          const SizedBox(width: 8),
          AppFilterChip(
            label: 'Movements',
            count: movementCount,
            selected: kind == StockReportKind.movements,
            onSelected: (_) => onSelected(StockReportKind.movements),
          ),
        ],
      ),
    );
  }
}

class _AsOfCard extends StatelessWidget {
  const _AsOfCard({required this.asOf, required this.onPick});

  final DateTime asOf;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('As of', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onPick,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              alignment: Alignment.centerLeft,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18),
                const SizedBox(width: 8),
                Text(StockDay.display(asOf)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.controller,
    required this.onPickFrom,
    required this.onPickTo,
  });

  final StockReportController controller;
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
  final StockReportPack pack;

  @override
  Widget build(BuildContext context) {
    final onHand = pack.kind == StockReportKind.onHand;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pack.rangeLabel.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            onHand ? 'On hand as of' : 'Movements',
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
          Text(
            onHand
                ? '${pack.productCount} products'
                : '${pack.movements.length} movements',
            style: AppTextStyles.pageTitle.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            onHand
                ? pack.negativeCount == 0
                      ? 'No negative on-hand'
                      : '${pack.negativeCount} negative'
                : 'In ${QuantityUtils.formatSigned(pack.inScaled)}  ·  Out ${QuantityUtils.formatSigned(pack.outScaled)}',
            style: AppTextStyles.secondaryBody.copyWith(color: Colors.white70),
          ),
        ],
      ),
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
              Text(StockDay.display(value), maxLines: 1),
            ],
          ),
        ),
      ],
    ),
  );
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
