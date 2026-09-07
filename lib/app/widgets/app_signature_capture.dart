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

Future<SignatureCaptureSource?> showSignatureSourceSheet(
  BuildContext context, {
  bool includeDraw = true,
}) {
  return showAppBottomSheet<SignatureCaptureSource>(
    context: context,
    title: 'Add signature',
    child: Builder(
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (includeDraw)
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

Future<Uint8List?> showSignaturePadDialog(
  BuildContext context, {
  Uint8List? existingPng,
}) {
  final size = MediaQuery.sizeOf(context);
  final tablet = ResponsiveUtils.isTablet(context);
  final height = math.min(
    size.height * (tablet ? 0.86 : 0.92),
    tablet ? 720.0 : 640.0,
  );
  return showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: tablet ? 28 : 12,
        vertical: tablet ? 24 : 12,
      ),
      child: SizedBox(
        width: tablet ? 760 : size.width,
        height: height,
        child: _SignaturePadSheet(existingPng: existingPng),
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

class AppSignaturePad extends StatefulWidget {
  const AppSignaturePad({
    this.padKey,
    this.placeholder = 'Sign here',
    this.borderRadius = 14,
    this.existingPng,
    this.onInkChanged,
    this.onInteractionChanged,
    super.key,
  });

  final Key? padKey;
  final String placeholder;
  final double borderRadius;
  final Uint8List? existingPng;
  final ValueChanged<bool>? onInkChanged;
  final ValueChanged<bool>? onInteractionChanged;

  @override
  State<AppSignaturePad> createState() => AppSignaturePadState();
}

class AppSignaturePadState extends State<AppSignaturePad> {
  final _boundaryKey = GlobalKey();
  final _strokes = <List<Offset>>[];
  List<Offset>? _current;
  Uint8List? _existing;

  @override
  void initState() {
    super.initState();
    _existing = widget.existingPng;
    if (_existing != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onInkChanged?.call(true);
      });
    }
  }

  bool get hasInk {
    if (_existing != null) return true;
    if (_current != null && _current!.length > 1) return true;
    return _strokes.any((stroke) => stroke.length > 1);
  }

  void clear() {
    setState(() {
      _strokes.clear();
      _current = null;
      _existing = null;
    });
    widget.onInkChanged?.call(false);
  }

  Future<Uint8List?> capturePng() async {
    if (!hasInk) return null;
    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }

  void _start(Offset point) {
    widget.onInteractionChanged?.call(true);
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
    widget.onInkChanged?.call(hasInk);
    widget.onInteractionChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        children: [
          RepaintBoundary(
            key: _boundaryKey,
            child: ColoredBox(
              color: Colors.white,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_existing != null)
                    Image.memory(_existing!, fit: BoxFit.contain),
                  GestureDetector(
                    key: widget.padKey ?? const Key('signature-pad'),
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) => _start(details.localPosition),
                    onPanUpdate: (details) => _move(details.localPosition),
                    onPanEnd: (_) => _end(),
                    onPanCancel: _end,
                    child: CustomPaint(
                      painter: _SignaturePainter(
                        strokes: _strokes,
                        current: _current,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!hasInk)
            IgnorePointer(
              child: Center(
                child: Text(
                  widget.placeholder,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SignaturePadSheet extends StatefulWidget {
  const _SignaturePadSheet({this.existingPng});

  final Uint8List? existingPng;

  @override
  State<_SignaturePadSheet> createState() => _SignaturePadSheetState();
}

class _SignaturePadSheetState extends State<_SignaturePadSheet> {
  final _padKey = GlobalKey<AppSignaturePadState>();
  late bool _hasInk = widget.existingPng != null;
  var _saving = false;

  Future<void> _save() async {
    if (!_hasInk || _saving) return;
    setState(() => _saving = true);
    try {
      final bytes = await _padKey.currentState?.capturePng();
      if (!mounted || bytes == null) return;
      Navigator.of(context).pop(bytes);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
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
            'Use the full pad. This appears on your invoices.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: AppSignaturePad(
                key: _padKey,
                existingPng: widget.existingPng,
                onInkChanged: (hasInk) => setState(() => _hasInk = hasInk),
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
                  onPressed: _hasInk
                      ? () => _padKey.currentState?.clear()
                      : null,
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
      ..strokeWidth = 3.2
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
