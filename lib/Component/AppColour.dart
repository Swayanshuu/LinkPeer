// AppColour.dart — kept for backward-compatibility.
// All color logic has moved to app_colors.dart.
// New code should import app_colors.dart directly.
export 'app_colors.dart';

// Alias so that existing code using AppColours.xxx still compiles.
// AppColours is now a typedef alias of AppColors.
import 'package:flutter/material.dart';
import 'app_colors.dart';

// ignore: camel_case_types
typedef AppColours = _AppColoursCompat;

/// Compatibility shim — provides the same static-const API that widgets
/// currently use, so no existing widget code needs to change.
/// All values are DARK theme values (the app was previously always dark).
/// New widgets should use AppColors.of(context) for theme-aware colours.
class _AppColoursCompat {
  const _AppColoursCompat._();

  static const Color bgColor = AppColors.bgColorDark;
  static const Color cardColor = AppColors.cardColorDark;
  static const Color borderColor = AppColors.borderColorDark;
  static const Color primaryText = AppColors.primaryTextDark;
  static const Color secondaryText = AppColors.secondaryTextDark;
}