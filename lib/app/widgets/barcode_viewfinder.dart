import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Green corner brackets that sit over the live camera preview.
class BarcodeViewfinder extends StatelessWidget {
  const BarcodeViewfinder({this.size = 220, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ViewfinderPainter()),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.success
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const arm = 28.0;
    final w = size.width;
    final h = size.height;
    final paths = [
      Path()
        ..moveTo(0, arm)
        ..lineTo(0, 0)
        ..lineTo(arm, 0),
      Path()
        ..moveTo(w - arm, 0)
        ..lineTo(w, 0)
        ..lineTo(w, arm),
      Path()
        ..moveTo(0, h - arm)
        ..lineTo(0, h)
        ..lineTo(arm, h),
      Path()
        ..moveTo(w - arm, h)
        ..lineTo(w, h)
        ..lineTo(w, h - arm),
    ];
    for (final path in paths) {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
