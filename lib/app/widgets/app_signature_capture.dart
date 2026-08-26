import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../constants/app_colors.dart';
import '../themes/app_text_styles.dart';
import '../utils/app_focus.dart';
import '../utils/responsive_utils.dart';
import 'app_bottom_sheet.dart';
import 'app_button.dart';
import 'app_outlined_button.dart';

enum SignatureCaptureSource { draw, gallery, camera }

/// Lets the user draw a signature or pick one from gallery/camera, then store
/// it through the same business-asset pipeline as logo and payment QR.
Future<String?> captureBusinessSignature({
  required BuildContext context,
  required Future<String?> Function(ImageSource source) pickImage,
  required Future<String> Function(Uint8List pngBytes) storeDrawing,
}) async {
  await AppFocus.dismissKeyboard();
  if (!context.mounted) return null;
  final source = await showSignatureSourceSheet(context);
  if (source == null || !context.mounted) return null;
  switch (source) {
    case SignatureCaptureSource.draw:
      final bytes = await showSignaturePadDialog(context);
      if (bytes == null) return null;
      return storeDrawing(bytes);
    case SignatureCaptureSource.gallery:
      return pickImage(ImageSource.gallery);
    case SignatureCaptureSource.camera:
      return pickImage(ImageSource.camera);
  }
}

Future<SignatureCaptureSource?> showSignatureSourceSheet(BuildContext context) {
  return showAppBottomSheet<SignatureCaptureSource>(
    context: context,
    title: 'Add signature',
    child: Builder(
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SourceAction(
            icon: Icons.draw_outlined,
            title: 'Draw signature',
            subtitle: 'Sign with your finger on a pad',
            onTap: () =>
                Navigator.pop(sheetContext, SignatureCaptureSource.draw),
          ),
          _SourceAction(
            icon: Icons.photo_library_outlined,
            title: 'Pick from gallery',
            subtitle: 'Use a saved photo of your signature',
            onTap: () =>
                Navigator.pop(sheetContext, SignatureCaptureSource.gallery),
          ),
          _SourceAction(
            icon: Icons.photo_camera_outlined,
            title: 'Take a photo',
            subtitle: 'Capture a signed paper with the camera',
            onTap: () =>
                Navigator.pop(sheetContext, SignatureCaptureSource.camera),
          ),
        ],
      ),
    ),
  );
}

Future<Uint8List?> showSignaturePadDialog(BuildContext context) {
  final tablet = ResponsiveUtils.isTablet(context);
  return showDialog<Uint8List>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: tablet ? 28 : 16,
        vertical: tablet ? 24 : 20,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: tablet ? 720 : 520,
          maxHeight: math.min(
            MediaQuery.sizeOf(dialogContext).height * 0.82,
            tablet ? 560 : 480,
          ),
        ),
        child: const _SignaturePadSheet(),
      ),
    ),
  );
}

class _SourceAction extends StatelessWidget {
  const _SourceAction({
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
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 72,
    contentPadding: EdgeInsets.zero,
    leading: Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.primary),
    ),
    title: Text(title, style: AppTextStyles.cardTitle),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 17),
    onTap: onTap,
  );
}

class _SignaturePadSheet extends StatefulWidget {
  const _SignaturePadSheet();

  @override
  State<_SignaturePadSheet> createState() => _SignaturePadSheetState();
}

class _SignaturePadSheetState extends State<_SignaturePadSheet> {
  final _boundaryKey = GlobalKey();
  final _strokes = <List<Offset>>[];
  List<Offset>? _current;
  var _saving = false;

  bool get _hasInk {
    if (_current != null && _current!.length > 1) return true;
    return _strokes.any((stroke) => stroke.length > 1);
  }

  void _start(Offset point) {
    setState(() => _current = [point]);
  }

  void _move(Offset point) {
    final stroke = _current;
    if (stroke == null) return;
    setState(() => stroke.add(point));
  }

  void _end() {
    final stroke = _current;
    if (stroke == null) return;
    setState(() {
      if (stroke.length > 1) _strokes.add(List<Offset>.from(stroke));
      _current = null;
    });
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _current = null;
    });
  }

  Future<void> _save() async {
    if (!_hasInk || _saving) return;
    setState(() => _saving = true);
    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (!mounted || data == null) return;
      Navigator.of(context).pop(data.buffer.asUint8List());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = math.min(
      ResponsiveUtils.isTablet(context) ? 300.0 : 220.0,
      MediaQuery.sizeOf(context).height * 0.38,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Draw signature',
                  style: AppTextStyles.sectionTitle,
                ),
              ),
              IconButton(
                tooltip: l10n('Close'),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Sign inside the box. This appears on your invoices.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Stack(
                  children: [
                    RepaintBoundary(
                      key: _boundaryKey,
                      child: ColoredBox(
                        color: Colors.white,
                        child: GestureDetector(
                          key: const Key('signature-pad'),
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (details) =>
                              _start(details.localPosition),
                          onPanUpdate: (details) =>
                              _move(details.localPosition),
                          onPanEnd: (_) => _end(),
                          child: CustomPaint(
                            painter: _SignaturePainter(
                              strokes: _strokes,
                              current: _current,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                    if (!_hasInk)
                      const IgnorePointer(
                        child: Center(
                          child: Text(
                            'Sign here',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppOutlinedButton(
                  label: 'Clear',
                  icon: Icons.refresh_rounded,
                  onPressed: _hasInk ? _clear : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'Use signature',
                  icon: Icons.check_rounded,
                  isLoading: _saving,
                  onPressed: _hasInk ? _save : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter({required this.strokes, required this.current});

  final List<List<Offset>> strokes;
  final List<Offset>? current;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in [...strokes, ?current]) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
