import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_amount_text.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../app/widgets/app_invoice_summary_card.dart';
import '../../../app/widgets/app_main_navigation.dart';
import '../../../app/widgets/responsive_content.dart';
import '../../../data/models/report_summary_model.dart';
import '../controllers/dashboard_controller.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: ResponsiveUtils.isTablet(context)
          ? null
          : const AppMainNavigation(current: MainDestination.home),
      appBar: AppBar(
        title: Obx(
          () => Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _businessInitial,
                  style: AppTextStyles.cardTitle.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting(), style: AppTextStyles.caption),
                    Text(
                      controller.profile.value?.businessName ??
                          'Creovo Billing',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Row(
        children: [
          if (ResponsiveUtils.isTablet(context)) _navigationRail(),
          Expanded(
            child: ResponsiveContent(
              tabletMaxWidth: 840,
              paddingTop: AppSpacing.xs,
              child: Obx(() {
                return ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: controller.reportLoading.value
                          ? const _DashboardOverviewLoadingCard()
                          : _businessOverview(context),
                    ),
                    if (!controller.reportLoading.value &&
                        controller.backupDue.value) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _BackupReminderPrompt(
                        onTap: () async {
                          await Get.toNamed<void>(AppRoutes.backup);
                          controller.refreshBackupStatus();
                        },
                      ),
                    ],
                    if (!controller.reportLoading.value &&
                        controller.report.value.outstandingMinor > 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _OutstandingPrompt(
                        amount: controller.report.value.outstandingMinor,
                        symbol: _symbol,
                        onTap: () => Get.toNamed<void>(AppRoutes.invoices),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    _SectionHeader(
                      title: 'Quick actions',
                      subtitle: 'Create and manage your business',
                      actionLabel: 'Reports',
                      actionIcon: Icons.insights_rounded,
                      onAction: () => Get.toNamed<void>(AppRoutes.reports),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (ResponsiveUtils.isTablet(context)) ...[
                      AppButton(
                        label: 'Create invoice',
                        icon: Icons.add_rounded,
                        onPressed: () =>
                            Get.toNamed<void>(AppRoutes.invoiceCreate),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    Row(
                      children: [
                        _QuickAction(
                          label: 'Estimate',
                          icon: Icons.request_quote_outlined,
                          onTap: () =>
                              Get.toNamed<void>(AppRoutes.quotationCreate),
                        ),
                        const SizedBox(width: 10),
                        _QuickAction(
                          label: 'Customer',
                          icon: Icons.person_add_alt_1_outlined,
                          onTap: () => Get.toNamed<void>(AppRoutes.customerAdd),
                        ),
                        const SizedBox(width: 10),
                        _QuickAction(
                          label: 'Product',
                          icon: Icons.add_box_outlined,
                          onTap: () => Get.toNamed<void>(AppRoutes.productAdd),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionHeader(
                      title: 'Recent invoices',
                      subtitle: controller.recentLoading.value
                          ? 'Loading billing activity'
                          : controller.recentInvoices.isEmpty
                          ? 'Latest billing activity'
                          : '${controller.recentInvoices.length} most recent',
                      actionLabel: 'View all',
                      onAction: () => Get.toNamed<void>(AppRoutes.invoices),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (controller.recentLoading.value)
                      const _RecentInvoicesLoading()
                    else if (controller.recentInvoices.isEmpty)
                      AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.receipt_long_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No invoices yet',
                                    style: AppTextStyles.cardTitle,
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Your latest invoices will appear here.',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ...[
                      for (var i = 0; i < controller.recentInvoices.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: i == controller.recentInvoices.length - 1
                                ? 0
                                : 10,
                          ),
                          child: AppInvoiceSummaryCard(
                            invoice: controller.recentInvoices[i],
                            currencySymbol: _symbol,
                            onTap: () => Get.toNamed<void>(
                              AppRoutes.invoiceDetails,
                              arguments: controller.recentInvoices[i].id,
                            ),
                          ),
                        ),
                    ],
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String get _symbol => controller.profile.value?.currencySymbol ?? '₹';

  String get _businessInitial {
    final name = controller.profile.value?.businessName.trim() ?? '';
    return name.isEmpty ? 'C' : name.characters.first.toUpperCase();
  }

  Widget _businessOverview(BuildContext context) {
    return DashboardOverviewCard(
      report: controller.report.value,
      symbol: _symbol,
    );
  }

  NavigationRail _navigationRail() => NavigationRail(
    selectedIndex: 0,
    labelType: NavigationRailLabelType.all,
    onDestinationSelected: (index) {
      final route = [
        AppRoutes.dashboard,
        AppRoutes.invoices,
        AppRoutes.customers,
        AppRoutes.more,
      ][index];
      if (index != 0) Get.offAllNamed<void>(route);
    },
    destinations: const [
      NavigationRailDestination(
        icon: Icon(Icons.home_outlined),
        label: Text('Home'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.receipt_long_outlined),
        label: Text('Invoices'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.people_outline),
        label: Text('Customers'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.grid_view_outlined),
        label: Text('More'),
      ),
    ],
  );

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class DashboardOverviewCard extends StatelessWidget {
  const DashboardOverviewCard({
    required this.report,
    required this.symbol,
    super.key,
  });

  final ReportSummaryModel report;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final collected = report.totalSalesMinor <= 0
        ? 0
        : ((report.totalReceivedMinor / report.totalSalesMinor) * 100)
              .clamp(0, 100)
              .round();
    return AppCard(
      color: isDark ? const Color(0xFF3B2038) : const Color(0xFFFCFAFF),
      borderColor: isDark ? AppColors.darkBorder : const Color(0xFFE9DFF0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Business overview', style: AppTextStyles.cardTitle),
                    const SizedBox(height: 1),
                    Text(
                      '${_monthName(DateTime.now().month)} cash flow',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${report.invoiceCount} ${report.invoiceCount == 1 ? 'invoice' : 'invoices'}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Invoiced this month',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          AppAmountText(
            amountMinor: report.totalSalesMinor,
            symbol: symbol,
            hero: true,
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 12),
          SizedBox(
            key: const ValueKey('dashboard-cash-flow'),
            height: 56,
            width: double.infinity,
            child: CustomPaint(
              painter: _CashFlowPainter(
                report.monthlySales.map((point) => point.amountMinor).toList(),
                isDark: isDark,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.border),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _OverviewMetric(
                  icon: Icons.south_rounded,
                  label: 'Received',
                  value: CurrencyUtils.formatMinor(
                    report.totalReceivedMinor,
                    symbol: symbol,
                  ),
                  color: AppColors.success,
                  background: AppColors.successLight,
                ),
              ),
              const _OverviewDivider(),
              Expanded(
                child: _OverviewMetric(
                  icon: Icons.schedule_rounded,
                  label: 'Outstanding',
                  value: CurrencyUtils.formatMinor(
                    report.outstandingMinor,
                    symbol: symbol,
                  ),
                  color: AppColors.warning,
                  background: AppColors.warningLight,
                ),
              ),
              const _OverviewDivider(),
              Expanded(
                child: _OverviewMetric(
                  icon: Icons.percent_rounded,
                  label: 'Collected',
                  value: '$collected%',
                  color: AppColors.secondary,
                  background: AppColors.secondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardOverviewLoadingCard extends StatelessWidget {
  const _DashboardOverviewLoadingCard();

  @override
  Widget build(BuildContext context) => AppCard(
    key: const ValueKey('dashboard-overview-loading'),
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3B2038)
        : const Color(0xFFFCFAFF),
    padding: const EdgeInsets.all(20),
    child: const SizedBox(
      height: 220,
      child: Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    ),
  );
}

class _RecentInvoicesLoading extends StatelessWidget {
  const _RecentInvoicesLoading();

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('dashboard-recent-loading'),
    children: List.generate(
      2,
      (index) => Padding(
        padding: EdgeInsets.only(bottom: index == 0 ? 10 : 0),
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: const SizedBox(
            height: 44,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.actionIcon,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.sectionTitle),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.small),
          ],
        ),
      ),
      TextButton.icon(
        onPressed: onAction,
        icon: actionIcon == null
            ? const SizedBox.shrink()
            : Icon(actionIcon, size: 18),
        label: Text(actionLabel),
      ),
    ],
  );
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 17),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        maxLines: 1,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
      ),
      const SizedBox(height: 5),
      SizedBox(
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            softWrap: false,
            style: AppTextStyles.small.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    ],
  );
}

class _OverviewDivider extends StatelessWidget {
  const _OverviewDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 62,
    margin: const EdgeInsets.symmetric(horizontal: 6),
    color: Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBorder
        : AppColors.border,
  );
}

String _monthName(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];

class _CashFlowPainter extends CustomPainter {
  const _CashFlowPainter(this.values, {required this.isDark});

  final List<int> values;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final points = values.isEmpty ? const <int>[0, 0, 0, 0, 0, 0] : values;
    final maximum = points.fold<int>(
      1,
      (max, value) => value > max ? value : max,
    );
    final path = Path();
    final fill = Path();
    for (var index = 0; index < points.length; index++) {
      final x = points.length == 1
          ? size.width
          : size.width * index / (points.length - 1);
      final normalized = points[index] / maximum;
      final y = size.height - 7 - (normalized * (size.height - 16));
      if (index == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
      if (index == points.length - 1) {
        fill.lineTo(x, y);
        fill.lineTo(x, size.height);
        fill.close();
      }
    }
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.secondary.withValues(alpha: .18),
            AppColors.secondary.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = isDark ? AppColors.accent : AppColors.secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final lastY =
        size.height - 7 - ((points.last / maximum) * (size.height - 16));
    canvas.drawCircle(
      Offset(size.width, lastY),
      3.5,
      Paint()..color = isDark ? AppColors.accent : AppColors.secondary,
    );
  }

  @override
  bool shouldRepaint(covariant _CashFlowPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.isDark != isDark;
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(height: 7),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    ),
  );
}

class _OutstandingPrompt extends StatelessWidget {
  const _OutstandingPrompt({
    required this.amount,
    required this.symbol,
    required this.onTap,
  });

  final int amount;
  final String symbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17),
      side: BorderSide(color: AppColors.warning.withValues(alpha: .30)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.schedule_send_outlined,
                color: AppColors.warning,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Follow up on payments', style: AppTextStyles.cardTitle),
                  const SizedBox(height: 2),
                  Text(
                    '${CurrencyUtils.formatMinor(amount, symbol: symbol)} is still waiting to be collected',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: AppColors.warning),
          ],
        ),
      ),
    ),
  );
}

class _BackupReminderPrompt extends StatelessWidget {
  const _BackupReminderPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3A242E)
        : const Color(0xFFFFF8F3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17),
      side: BorderSide(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkBorder
            : const Color(0xFFF5DED2),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.backup_outlined,
                color: AppColors.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Backup due', style: AppTextStyles.cardTitle),
                  const SizedBox(height: 2),
                  Text(
                    'Protect your latest data with a local backup',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primary,
                size: 19,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
