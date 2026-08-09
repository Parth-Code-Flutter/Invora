import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

enum AppDeviceType { phone, tablet, largeTablet }

/// Shared phone and tablet sizing helpers.
///
/// Inspired by Smart Inspection's responsive utility, while using clamped
/// logical-pixel scaling so Invora does not require a separate sizing package.
abstract final class ResponsiveUtils {
  static AppDeviceType deviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppConstants.largeTabletBreakpoint) {
      return AppDeviceType.largeTablet;
    }
    if (width >= AppConstants.tabletBreakpoint) return AppDeviceType.tablet;
    return AppDeviceType.phone;
  }

  static bool isPhone(BuildContext context) =>
      deviceType(context) == AppDeviceType.phone;

  static bool isTablet(BuildContext context) => !isPhone(context);

  static bool isLargeTablet(BuildContext context) =>
      deviceType(context) == AppDeviceType.largeTablet;

  static double width(BuildContext context, double designWidth) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final designCanvas = isTablet(context) ? 834.0 : 390.0;
    final scale = (screenWidth / designCanvas).clamp(0.88, 1.18);
    return designWidth * scale;
  }

  static double height(BuildContext context, double designHeight) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final designCanvas = isTablet(context) ? 1194.0 : 844.0;
    final scale = (screenHeight / designCanvas).clamp(0.88, 1.14);
    return designHeight * scale;
  }

  static double fontSize(BuildContext context, double designFontSize) {
    final accessibilityScale = MediaQuery.textScalerOf(context).scale(1);
    final deviceScale = isTablet(context) ? 1.08 : 1.0;
    return designFontSize * deviceScale * math.min(accessibilityScale, 1.3);
  }

  static EdgeInsets onlyPadding(
    BuildContext context, {
    double top = 0,
    double bottom = 0,
    double left = 0,
    double right = 0,
  }) {
    return EdgeInsets.only(
      top: height(context, top),
      bottom: height(context, bottom),
      left: width(context, left),
      right: width(context, right),
    );
  }

  static EdgeInsets symmetricPadding(
    BuildContext context, {
    double horizontal = 0,
    double vertical = 0,
  }) {
    return EdgeInsets.symmetric(
      horizontal: width(context, horizontal),
      vertical: height(context, vertical),
    );
  }

  static Widget verticalGap(BuildContext context, double gap) =>
      SizedBox(height: height(context, gap));

  static Widget horizontalGap(BuildContext context, double gap) =>
      SizedBox(width: width(context, gap));

  static double horizontalPadding(BuildContext context) {
    final base = switch (deviceType(context)) {
      AppDeviceType.phone => width(context, 20),
      AppDeviceType.tablet => width(context, 28),
      AppDeviceType.largeTablet => width(context, 36),
    };
    final screenWidth = MediaQuery.sizeOf(context).width;
    final centeredGutter = (screenWidth - AppConstants.maxContentWidth) / 2;
    return math.max(base, centeredGutter + base);
  }

  static double contentMaxWidth(
    BuildContext context, {
    double tablet = 900,
    double largeTablet = AppConstants.maxContentWidth,
  }) {
    return isLargeTablet(context) ? largeTablet : tablet;
  }

  static int gridColumns(
    BuildContext context, {
    int tablet = 2,
    int largeTablet = 3,
  }) {
    return switch (deviceType(context)) {
      AppDeviceType.phone => 1,
      AppDeviceType.tablet => tablet,
      AppDeviceType.largeTablet => largeTablet,
    };
  }

  static int formColumns(BuildContext context) => isTablet(context) ? 2 : 1;
}
