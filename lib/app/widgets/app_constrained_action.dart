import 'package:flutter/material.dart';

import '../utils/responsive_utils.dart';

/// Keeps phone CTAs full-width. On tablet, centres the same control at a
/// readable max width instead of stretching it across the canvas.
///
/// [heightFactor] stays 1 so this can sit in a [Scaffold.bottomNavigationBar]
/// without expanding and collapsing the page body.
class AppConstrainedAction extends StatelessWidget {
  const AppConstrainedAction({required this.child, this.maxWidth, super.key});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!ResponsiveUtils.isTablet(context)) return child;
    return Align(
      alignment: Alignment.center,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? ResponsiveUtils.actionMaxWidth(context),
        ),
        child: child,
      ),
    );
  }
}
