import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../constants/app_colors.dart';

class AppListEntrance extends StatelessWidget {
  const AppListEntrance({required this.index, required this.child, super.key});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final delay = Duration(milliseconds: 35 * index.clamp(0, 8));
    return TweenAnimationBuilder<double>(
      key: ValueKey('list-entrance-$index'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Interval(
        (delay.inMilliseconds / 700).clamp(0, .45),
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: Transform.scale(
            scale: .985 + (.015 * value),
            alignment: Alignment.topCenter,
            child: child,
          ),
        ),
      ),
      child: child,
    );
  }
}

/// Adds a restrained depth effect while a list row moves through the viewport.
///
/// Rows stay fully readable and only soften slightly near the viewport edges.
/// Motion is disabled automatically when the platform's reduced-motion setting
/// is enabled.
class AppScrollMotion extends StatefulWidget {
  const AppScrollMotion({required this.child, super.key});

  final Widget child;

  @override
  State<AppScrollMotion> createState() => _AppScrollMotionState();
}

class _AppScrollMotionState extends State<AppScrollMotion> {
  final _childKey = GlobalKey();
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position = Scrollable.maybeOf(context)?.position;
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    final child = KeyedSubtree(key: _childKey, child: widget.child);
    if (position == null || MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    return AnimatedBuilder(
      animation: position,
      child: child,
      builder: (context, child) {
        final renderObject = _childKey.currentContext?.findRenderObject();
        if (renderObject == null || !renderObject.attached) return child!;
        final viewport = RenderAbstractViewport.maybeOf(renderObject);
        if (viewport == null || !position.hasContentDimensions) return child!;

        final centeredOffset = viewport
            .getOffsetToReveal(renderObject, 0.5)
            .offset;
        final distanceFromCenter = (centeredOffset - position.pixels).abs();
        final range = position.viewportDimension * 0.62;
        final edgeFactor = range <= 0
            ? 0.0
            : (distanceFromCenter / range).clamp(0.0, 1.0);
        final scale = 1 - (edgeFactor * 0.014);
        final opacity = 1 - (edgeFactor * 0.06);

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
    );
  }
}

class AppListSkeleton extends StatefulWidget {
  const AppListSkeleton({this.itemCount = 6, super.key});
  final int itemCount;

  @override
  State<AppListSkeleton> createState() => _AppListSkeletonState();
}

class _AppListSkeletonState extends State<AppListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width < 600 ? 20.0 : 28.0;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 100),
        itemCount: widget.itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, index) => Container(
          height: 76,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + (_animation.value * 3), 0),
              end: Alignment(-.5 + (_animation.value * 3), 0),
              colors: [
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : AppColors.surfaceSoft,
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSurfaceVariant
                    : Colors.white,
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : AppColors.surfaceSoft,
              ],
            ),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBorder
                  : AppColors.border,
            ),
          ),
        ),
      ),
    );
  }
}
