import 'package:flutter/widgets.dart';

import '../constants/app_constants.dart';

abstract final class ResponsiveUtils {
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppConstants.tabletBreakpoint;

  static double horizontalPadding(BuildContext context) =>
      isTablet(context) ? 32 : 20;

  static int gridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 3;
    if (width >= AppConstants.tabletBreakpoint) return 2;
    return 1;
  }
}
