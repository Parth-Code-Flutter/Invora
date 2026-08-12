import 'package:flutter/material.dart';

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
