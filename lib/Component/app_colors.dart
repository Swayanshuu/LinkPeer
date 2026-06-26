import 'package:flutter/material.dart';

class AppColors {
  final Color bgColor;
  final Color cardColor;
  final Color borderColor;
  final Color primaryText;
  final Color secondaryText;

  const AppColors._({
    required this.bgColor,
    required this.cardColor,
    required this.borderColor,
    required this.primaryText,
    required this.secondaryText,
  });

  // DARK THEME
  static const AppColors _dark = AppColors._(
    bgColor: Color(0xff141413), // Claude dark background
    cardColor: Color(0xff1E1E1C), // Neutral dark card surface
    borderColor: Color(0xff2C2C29), // Subtle grey border
    primaryText: Color(0xffF7F7F5), // Clean soft white text
    secondaryText: Color(0xffA1A1A0), // Muted secondary grey text
  );

  // LIGHT THEME
  static const AppColors _light = AppColors._(
    bgColor: Color(0xffF5F5F3), // Warm off-white background
    cardColor: Color(0xffFFFFFF), // Pure white card surface
    borderColor: Color(0xffE0E0DE), // Soft grey border
    primaryText: Color(0xff181817), // Deep near-black text
    secondaryText: Color(0xff6B6B6A), // Muted dark grey secondary text
  );

  // ACCESSOR
  static AppColors of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? _dark : _light;
  }

  // LEGACY STATIC ACCESS
  static const Color bgColorDark = Color(0xff141413);
  static const Color cardColorDark = Color(0xff1E1E1C);
  static const Color borderColorDark = Color(0xff2C2C29);
  static const Color primaryTextDark = Color(0xffF7F7F5);
  static const Color secondaryTextDark = Color(0xffA1A1A0);

  static const Color bgColorLight = Color(0xffF5F5F3);
  static const Color cardColorLight = Color(0xffFFFFFF);
  static const Color borderColorLight = Color(0xffE0E0DE);
  static const Color primaryTextLight = Color(0xff181817);
  static const Color secondaryTextLight = Color(0xff6B6B6A);
}
