import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/currency_utils.dart';
import '../../../data/models/report_summary_model.dart';

enum ReportChartStyle { trend, bars }

class ReportYearChart extends StatelessWidget {
  const ReportYearChart({
    required this.points,
    required this.style,
    required this.symbol,
    required this.highlightIndex,
    required this.onSelect,
    super.key,
  });

  final List<MonthlySalesPoint> points;
  final ReportChartStyle style;
  final String symbol;
  final int highlightIndex;
  final ValueChanged<int> onSelect;

  static const months = [
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

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox(height: 200);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = highlightIndex.clamp(0, points.length - 1);
    final max = points.fold<int>(1, (value, point) {
      final peak = math.max(point.amountMinor, point.receivedMinor);
      return peak > value ? peak : value;
    });
    final selectedPoint = points[selected];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CalloutChip(
              label: CurrencyUtils.formatMinor(
                selectedPoint.amountMinor,
                symbol: symbol,
              ),
              color: AppColors.primary,
              filled: true,
            ),
            _CalloutChip(
              label: CurrencyUtils.formatMinor(
                selectedPoint.receivedMinor,
                symbol: symbol,
              ),
              color: AppColors.accent,
              filled: false,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 196,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 42,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _axisLabel(max, symbol, isDark),
                    _axisLabel(max ~/ 2, symbol, isDark),
                    _axisLabel(0, symbol, isDark),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        final slot = constraints.maxWidth / points.length;
                        onSelect(
                          (details.localPosition.dx / slot).floor().clamp(
                            0,
                            points.length - 1,
                          ),
                        );
                      },
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _YearChartPainter(
                          sales: [
                            for (final point in points)
                              point.amountMinor.toDouble(),
                          ],
                          received: [
                            for (final point in points)
                              point.receivedMinor.toDouble(),
                          ],
                          maxMinor: max.toDouble(),
                          highlightIndex: selected,
                          bars: style == ReportChartStyle.bars,
                          isDark: isDark,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var index = 0; index < points.length; index++)
              Expanded(
                child: Text(
                  index == selected
                      ? months[points[index].month.month - 1]
                      : months[points[index].month.month - 1][0],
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    fontWeight: index == selected
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: index == selected
                        ? AppColors.secondary
                        : AppColors.textTertiary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static Widget _axisLabel(int minor, String symbol, bool isDark) {
    return Text(
      CurrencyUtils.compactMinor(minor, symbol: symbol),
      style: AppTextStyles.caption.copyWith(
        fontSize: 10,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
      ),
    );
  }
}

class _CalloutChip extends StatelessWidget {
  const _CalloutChip({
    required this.label,
    required this.color,
    required this.filled,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(10),
        border: filled ? null : Border.all(color: color, width: 1.4),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: filled ? Colors.white : color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _YearChartPainter extends CustomPainter {
  const _YearChartPainter({
    required this.sales,
    required this.received,
    required this.maxMinor,
    required this.highlightIndex,
    required this.bars,
    required this.isDark,
  });

  final List<double> sales;
  final List<double> received;
  final double maxMinor;
  final int highlightIndex;
  final bool bars;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (sales.isEmpty || size.height <= 0 || size.width <= 0) return;
    final n = sales.length;
    final gridColor = (isDark ? AppColors.darkBorder : AppColors.border)
        .withValues(alpha: .85);

    for (final t in const [0.0, 0.5, 1.0]) {
      final y = size.height - 4 - t * (size.height - 10);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = gridColor
          ..strokeWidth = 1,
      );
    }

    Offset pointAt(List<double> values, int index) {
      final slot = size.width / n;
      final x = n == 1 ? size.width / 2 : slot * (index + 0.5);
      final usable = size.height - 10;
      final y =
          size.height -
          4 -
          (values[index].clamp(0, maxMinor) / maxMinor) * usable;
      return Offset(x, y);
    }

    final selectedX = pointAt(sales, highlightIndex.clamp(0, n - 1)).dx;
    final dash = Paint()
      ..color = AppColors.secondary.withValues(alpha: .35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const dashWidth = 4.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(selectedX, y),
        Offset(selectedX, math.min(y + dashWidth, size.height)),
        dash,
      );
      y += dashWidth * 2;
    }

    if (bars) {
      final slot = size.width / n;
      final barWidth = math.min(14.0, slot * 0.42);
      for (var index = 0; index < n; index++) {
        final center = pointAt(sales, index);
        final zero = sales[index] <= 0;
        final top = zero ? size.height - 10 : center.dy;
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx, (top + size.height - 4) / 2),
            width: barWidth,
            height: math.max(6, size.height - 4 - top),
          ),
          const Radius.circular(7),
        );
        final color = zero
            ? AppColors.primary.withValues(alpha: .12)
            : index == highlightIndex
            ? AppColors.primary
            : AppColors.secondary.withValues(alpha: .55);
        canvas.drawRRect(rect, Paint()..color = color);
      }
      return;
    }

    Path lineFor(List<double> values) {
      final path = Path()..moveTo(pointAt(values, 0).dx, pointAt(values, 0).dy);
      for (var index = 1; index < n; index++) {
        final previous = pointAt(values, index - 1);
        final current = pointAt(values, index);
        final midX = (previous.dx + current.dx) / 2;
        path.cubicTo(
          midX,
          previous.dy,
          midX,
          current.dy,
          current.dx,
          current.dy,
        );
      }
      return path;
    }

    final salesPath = lineFor(sales);
    final area = Path.from(salesPath)
      ..lineTo(pointAt(sales, n - 1).dx, size.height - 4)
      ..lineTo(pointAt(sales, 0).dx, size.height - 4)
      ..close();
    canvas.drawPath(
      area,
      Paint()..color = AppColors.primary.withValues(alpha: .14),
    );
    canvas.drawPath(
      salesPath,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      lineFor(received),
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final selected = pointAt(sales, highlightIndex.clamp(0, n - 1));
    canvas.drawCircle(selected, 6.5, Paint()..color = AppColors.primary);
    canvas.drawCircle(selected, 3, Paint()..color = Colors.white);
    final receivedPoint = pointAt(received, highlightIndex.clamp(0, n - 1));
    canvas.drawCircle(receivedPoint, 5, Paint()..color = AppColors.accent);
    canvas.drawCircle(receivedPoint, 2.2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _YearChartPainter oldDelegate) =>
      oldDelegate.sales != sales ||
      oldDelegate.received != received ||
      oldDelegate.highlightIndex != highlightIndex ||
      oldDelegate.maxMinor != maxMinor ||
      oldDelegate.bars != bars ||
      oldDelegate.isDark != isDark;
}

class ReportSegmentedStyle extends StatelessWidget {
  const ReportSegmentedStyle({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ReportChartStyle value;
  final ValueChanged<ReportChartStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tab('Line', ReportChartStyle.trend),
          _tab('Bars', ReportChartStyle.bars),
        ],
      ),
    );
  }

  Widget _tab(String label, ReportChartStyle style) {
    final selected = value == style;
    return GestureDetector(
      onTap: () => onChanged(style),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class ReportCollectionCard extends StatelessWidget {
  const ReportCollectionCard({
    required this.salesMinor,
    required this.receivedMinor,
    required this.outstandingMinor,
    required this.symbol,
    required this.periodLabel,
    required this.trendLabel,
    required this.trendUp,
    this.onOutstanding,
    super.key,
  });

  final int salesMinor;
  final int receivedMinor;
  final int outstandingMinor;
  final String symbol;
  final String periodLabel;
  final String? trendLabel;
  final bool trendUp;
  final VoidCallback? onOutstanding;

  @override
  Widget build(BuildContext context) {
    final total = math.max(salesMinor, 1);
    final progress = (receivedMinor / total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Net sales', style: AppTextStyles.sectionTitle),
              ),
              Text(
                periodLabel,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: Text(
              CurrencyUtils.formatMinor(salesMinor, symbol: symbol),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.pageTitle.copyWith(fontSize: 28),
            ),
          ),
          if (trendLabel != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  trendUp
                      ? Icons.arrow_outward_rounded
                      : Icons.south_east_rounded,
                  size: 16,
                  color: trendUp ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    trendLabel!,
                    style: AppTextStyles.caption.copyWith(
                      color: trendUp ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _TargetStat(
                  label: 'Received',
                  amountMinor: receivedMinor,
                  symbol: symbol,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onOutstanding,
                  child: _TargetStat(
                    label: 'Outstanding',
                    amountMinor: outstandingMinor,
                    symbol: symbol,
                    alignEnd: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CollectionTrack(progress: progress),
        ],
      ),
    );
  }
}

class _TargetStat extends StatelessWidget {
  const _TargetStat({
    required this.label,
    required this.amountMinor,
    required this.symbol,
    this.alignEnd = false,
  });

  final String label;
  final int amountMinor;
  final String symbol;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          CurrencyUtils.formatMinor(amountMinor, symbol: symbol),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.listAmount,
        ),
      ],
    );
  }
}

class _CollectionTrack extends StatelessWidget {
  const _CollectionTrack({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final thumb = 22.0;
        final x = ((constraints.maxWidth - thumb) * progress).clamp(
          0,
          constraints.maxWidth - thumb,
        );
        return SizedBox(
          height: 22,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: SizedBox(
                    height: 10,
                    width: constraints.maxWidth,
                    child: Stack(
                      children: [
                        const ColoredBox(
                          color: AppColors.surfaceMuted,
                          child: SizedBox.expand(),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.02, 1),
                          child: const ColoredBox(color: AppColors.accent),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: x.toDouble(),
                top: 0,
                child: Container(
                  width: thumb,
                  height: thumb,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ReportKpiTile extends StatelessWidget {
  const ReportKpiTile({
    required this.label,
    required this.amountMinor,
    required this.symbol,
    required this.color,
    this.deltaLabel,
    this.deltaUp = true,
    this.onTap,
    super.key,
  });

  final String label;
  final int amountMinor;
  final String symbol;
  final Color color;
  final String? deltaLabel;
  final bool deltaUp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBorder
                  : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Icon(Icons.north_east_rounded, size: 14, color: color),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: Text(
                  CurrencyUtils.formatMinor(amountMinor, symbol: symbol),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.pageTitle.copyWith(
                    fontSize: 20,
                    color: color,
                  ),
                ),
              ),
              if (deltaLabel != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      deltaUp
                          ? Icons.arrow_drop_up_rounded
                          : Icons.arrow_drop_down_rounded,
                      size: 18,
                      color: deltaUp ? AppColors.success : AppColors.error,
                    ),
                    Flexible(
                      child: Text(
                        deltaLabel!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ReportStatusDonut extends StatelessWidget {
  const ReportStatusDonut({
    required this.created,
    required this.paid,
    required this.pending,
    required this.creditNoteCount,
    this.onPaid,
    this.onPending,
    super.key,
  });

  final int created;
  final int paid;
  final int pending;
  final int creditNoteCount;
  final VoidCallback? onPaid;
  final VoidCallback? onPending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Invoice mix', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 108,
                height: 108,
                child: CustomPaint(
                  painter: _DonutPainter(paid: paid, pending: pending),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$created', style: AppTextStyles.pageTitle),
                        Text(
                          'Created',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _LegendRow(
                      color: AppColors.accent,
                      label: 'Paid',
                      value: paid,
                      total: created,
                      onTap: onPaid,
                    ),
                    const SizedBox(height: 10),
                    _LegendRow(
                      color: AppColors.primary,
                      label: 'Pending',
                      value: pending,
                      total: created,
                      onTap: onPending,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (creditNoteCount > 0) ...[
            const SizedBox(height: 12),
            Text(
              creditNoteCount == 1
                  ? 'Net of 1 credit note'
                  : 'Net of $creditNoteCount credit notes',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
    required this.total,
    this.onTap,
  });

  final Color color;
  final String label;
  final int value;
  final int total;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final percent = total <= 0 ? 0 : (value / total * 100).round();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppTextStyles.listName)),
          Text(
            '$value  ·  $percent%',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.paid, required this.pending});
  final int paid;
  final int pending;

  @override
  void paint(Canvas canvas, Size size) {
    final total = math.max(paid + pending, 1);
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.butt;
    final start = -math.pi / 2;
    if (paid + pending == 0) {
      canvas.drawArc(
        rect.deflate(10),
        0,
        math.pi * 2,
        false,
        paint..color = AppColors.border,
      );
      return;
    }
    final paidSweep = (paid / total) * math.pi * 2;
    final pendingSweep = (pending / total) * math.pi * 2;
    canvas.drawArc(
      rect.deflate(10),
      start,
      paidSweep * 0.96,
      false,
      paint..color = AppColors.accent,
    );
    canvas.drawArc(
      rect.deflate(10),
      start + paidSweep,
      pendingSweep * 0.96,
      false,
      paint..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.paid != paid || oldDelegate.pending != pending;
}
