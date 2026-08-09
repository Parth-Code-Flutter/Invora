import 'package:flutter/widgets.dart';

/// Shared spacing and shape tokens used throughout Invora's UI.
abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  static const screenPadding = EdgeInsets.symmetric(horizontal: lg);
  static const cardPadding = EdgeInsets.all(md);
  static const cardRadius = 16.0;
  static const inputRadius = 12.0;
  static const buttonRadius = 14.0;
  static const bottomSheetRadius = 24.0;
  static const buttonHeight = 52.0;
  static const minTouchTarget = 48.0;
}
