import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../constants/app_colors.dart';
import '../themes/app_text_styles.dart';
import 'app_amount_text.dart';

/// Branded header used by Sales and Purchase home snapshots.
class AppSnapshotHero extends StatelessWidget {
  const AppSnapshotHero({
    required this.title,
    required this.amountCaption,
    required this.amountMinor,
    required this.symbol,
    required this.progress,
    required this.ringCaption,
    this.subtitle,
    this.trailing,
    this.sparkline = const [],
    this.trendLabel,
    this.onAmountTap,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String amountCaption;
  final int amountMinor;
  final String symbol;
  final double progress;
  final String ringCaption;
  final Widget? trailing;
  final List<double> sparkline;
  final String? trendLabel;
  final VoidCallback? onAmountTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(
        painter: const _HeroOrbPainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.listName.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: .8),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                amountCaption,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(alpha: .8),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: onAmountTap,
                          child: AppAmountText(
                            amountMinor: amountMinor,
                            symbol: symbol,
                            color: Colors.white,
                            textAlign: TextAlign.start,
                            style: AppTextStyles.pageTitle.copyWith(
                              color: Colors.white,
                              fontSize: 26,
                            ),
                          ),
                        ),
                        if (trendLabel != null) ...[
                          const SizedBox(height: 6),
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
                              trendLabel!,
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
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppProgressRing(
                        progress: progress,
                        label: '${(progress * 100).round()}%',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ringCaption,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: .8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (sparkline.length >= 2) ...[
                const SizedBox(height: 12),
                AppSparkline(values: sparkline),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppSnapshotBadge extends StatelessWidget {
  const AppSnapshotBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeroOrbPainter extends CustomPainter {
  const _HeroOrbPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .1);
    canvas.drawCircle(Offset(size.width - 8, -8), 56, paint);
    canvas.drawCircle(Offset(size.width - 92, size.height + 10), 43, paint);
  }

  @override
  bool shouldRepaint(covariant _HeroOrbPainter oldDelegate) => false;
}

/// Compact circular progress used on Sales and Purchase snapshot heroes.
class AppProgressRing extends StatelessWidget {
  const AppProgressRing({
    required this.progress,
    required this.label,
    this.size = 54,
    this.color = Colors.white,
    super.key,
  });

  final double progress;
  final String label;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress: progress.clamp(0, 1), color: color),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 4;
    final track = Paint()
      ..color = color.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class AppSparkline extends StatelessWidget {
  const AppSparkline({
    required this.values,
    this.color = Colors.white,
    this.height = 36,
    super.key,
  });

  final List<double> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(values: values, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final max = values.reduce(math.max);
    final min = values.reduce(math.min);
    final range = (max - min).abs() < 1 ? 1.0 : max - min;
    final path = Path();
    final fill = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * size.width / (values.length - 1);
      final y =
          size.height - ((values[i] - min) / range) * (size.height - 4) - 2;
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();
    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: .16));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

/// Tinted breakdown chip so snapshot amounts stay readable on a narrow phone.
class AppMetricChip extends StatelessWidget {
  const AppMetricChip({
    required this.label,
    required this.amountMinor,
    required this.symbol,
    required this.color,
    required this.icon,
    this.onTap,
    super.key,
  });

  final String label;
  final int amountMinor;
  final String symbol;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 3),
          AppAmountText(
            amountMinor: amountMinor,
            symbol: symbol,
            color: color,
            textAlign: TextAlign.start,
            style: AppTextStyles.listAmount.copyWith(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: chip,
      ),
    );
  }
}
