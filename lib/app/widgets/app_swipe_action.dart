import 'dart:async';

import 'package:flutter/material.dart' hide Text;

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../constants/app_colors.dart';
import '../themes/app_text_styles.dart';

class AppSwipeAction extends StatefulWidget {
  const AppSwipeAction({
    required this.label,
    required this.onCompleted,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final FutureOr<void> Function()? onCompleted;
  final bool isLoading;

  @override
  State<AppSwipeAction> createState() => _AppSwipeActionState();
}

class _AppSwipeActionState extends State<AppSwipeAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hintAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);
  double _progress = 0;
  bool _dragging = false;
  bool _submitting = false;

  bool get _disabled => widget.onCompleted == null;
  bool get _busy => widget.isLoading || _submitting;

  @override
  void dispose() {
    _hintAnimation.dispose();
    super.dispose();
  }

  void _updateDrag(DragUpdateDetails details, double travel) {
    if (_disabled || _busy || travel <= 0) return;
    setState(() {
      _dragging = true;
      _progress = (_progress + (details.delta.dx / travel)).clamp(0, 1);
    });
  }

  Future<void> _finishDrag() async {
    if (_disabled || _busy) return;
    if (_progress < 0.78) {
      setState(() {
        _dragging = false;
        _progress = 0;
      });
      return;
    }
    setState(() {
      _dragging = false;
      _progress = 1;
      _submitting = true;
    });
    try {
      await widget.onCompleted?.call();
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _progress = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      enabled: !_disabled && !_busy,
      label: widget.label,
      hint: 'Swipe right to confirm',
      onTap: _disabled || _busy ? null : () => widget.onCompleted?.call(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const height = 58.0;
          const thumbSize = 48.0;
          const inset = 5.0;
          final travel = constraints.maxWidth - thumbSize - (inset * 2);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) => _updateDrag(details, travel),
            onHorizontalDragEnd: (_) => _finishDrag(),
            onHorizontalDragCancel: () {
              if (mounted && !_busy) {
                setState(() {
                  _dragging = false;
                  _progress = 0;
                });
              }
            },
            child: Container(
              height: height,
              decoration: BoxDecoration(
                gradient: _disabled
                    ? null
                    : const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                color: _disabled ? AppColors.textTertiary : null,
                borderRadius: BorderRadius.circular(18),
                boxShadow: _disabled
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 140),
                    opacity: (1 - (_progress * 0.82)).clamp(0, 1),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(62, 0, 16, 0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.label,
                              maxLines: 1,
                              style: AppTextStyles.button.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedBuilder(
                              animation: _hintAnimation,
                              builder: (_, child) => Opacity(
                                opacity: reduceMotion
                                    ? 0.78
                                    : 0.42 + (_hintAnimation.value * 0.46),
                                child: Transform.translate(
                                  offset: Offset(
                                    reduceMotion ? 0 : _hintAnimation.value * 3,
                                    0,
                                  ),
                                  child: child,
                                ),
                              ),
                              child: const Icon(
                                Icons.keyboard_double_arrow_right_rounded,
                                color: Colors.white,
                                size: 21,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: _dragging
                        ? Duration.zero
                        : const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    left: inset + (travel * _progress),
                    top: inset,
                    child: Container(
                      width: thumbSize,
                      height: thumbSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _busy
                            ? const SizedBox(
                                width: 21,
                                height: 21,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: AppColors.primary,
                                ),
                              )
                            : Icon(
                                _progress >= 0.78
                                    ? Icons.check_rounded
                                    : Icons.arrow_forward_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
