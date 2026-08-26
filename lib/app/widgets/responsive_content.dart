import 'package:flutter/material.dart';

import '../utils/responsive_utils.dart';

class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    required this.child,
    this.paddingTop = 0,
    this.paddingBottom = 24,
    this.tabletMaxWidth = 900,
    this.largeTabletMaxWidth = 1200,
    super.key,
  });

  final Widget child;
  final double paddingTop;
  final double paddingBottom;
  final double tabletMaxWidth;
  final double largeTabletMaxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveUtils.contentMaxWidth(
            context,
            tablet: tabletMaxWidth,
            largeTablet: largeTabletMaxWidth,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: ResponsiveUtils.horizontalPadding(context),
            right: ResponsiveUtils.horizontalPadding(context),
            top: ResponsiveUtils.height(context, paddingTop),
            bottom: ResponsiveUtils.height(context, paddingBottom),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Centres a form at a readable tablet width. Phone layouts pass through.
class AppFormCanvas extends StatelessWidget {
  const AppFormCanvas({required this.child, this.maxWidth, super.key});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!ResponsiveUtils.isTablet(context)) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? ResponsiveUtils.formMaxWidth(context),
        ),
        child: child,
      ),
    );
  }
}
