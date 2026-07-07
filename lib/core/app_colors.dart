import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color bgColor;
  final Color cardColor;
  final Color borderColor;
  final Color primaryText;
  final Color secondaryText;

  // Custom Badge Colors
  final Color badgeAlumniBg;
  final Color badgeAlumniText;
  final Color badgeStudentBg;
  final Color badgeStudentText;
  final Color badgeAdminBg;
  final Color badgeAdminText;
  final Color badgeFacultyBg;
  final Color badgeFacultyText;

  // Custom Card Colors
  final Color announcementBg;
  final Color announcementBorder;
  final Color adminPostBg;
  final Color adminPostBorder;

  // UI Accents
  final Color primaryAccent;
  final Color onPrimaryAccent;
  final Color successColor;

  // Category Accents
  final Color categoryJob;
  final Color categoryInternship;
  final Color categoryAnnouncement;

  const AppColors({
    required this.bgColor,
    required this.cardColor,
    required this.borderColor,
    required this.primaryText,
    required this.secondaryText,
    required this.badgeAlumniBg,
    required this.badgeAlumniText,
    required this.badgeStudentBg,
    required this.badgeStudentText,
    required this.badgeAdminBg,
    required this.badgeAdminText,
    required this.badgeFacultyBg,
    required this.badgeFacultyText,
    required this.announcementBg,
    required this.announcementBorder,
    required this.adminPostBg,
    required this.adminPostBorder,
    required this.primaryAccent,
    required this.onPrimaryAccent,
    required this.successColor,
    required this.categoryJob,
    required this.categoryInternship,
    required this.categoryAnnouncement,
  });

  @override
  AppColors copyWith({
    Color? bgColor,
    Color? cardColor,
    Color? borderColor,
    Color? primaryText,
    Color? secondaryText,
    Color? badgeAlumniBg,
    Color? badgeAlumniText,
    Color? badgeStudentBg,
    Color? badgeStudentText,
    Color? badgeAdminBg,
    Color? badgeAdminText,
    Color? badgeFacultyBg,
    Color? badgeFacultyText,
    Color? announcementBg,
    Color? announcementBorder,
    Color? adminPostBg,
    Color? adminPostBorder,
    Color? primaryAccent,
    Color? onPrimaryAccent,
    Color? successColor,
    Color? categoryJob,
    Color? categoryInternship,
    Color? categoryAnnouncement,
  }) {
    return AppColors(
      bgColor: bgColor ?? this.bgColor,
      cardColor: cardColor ?? this.cardColor,
      borderColor: borderColor ?? this.borderColor,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      badgeAlumniBg: badgeAlumniBg ?? this.badgeAlumniBg,
      badgeAlumniText: badgeAlumniText ?? this.badgeAlumniText,
      badgeStudentBg: badgeStudentBg ?? this.badgeStudentBg,
      badgeStudentText: badgeStudentText ?? this.badgeStudentText,
      badgeAdminBg: badgeAdminBg ?? this.badgeAdminBg,
      badgeAdminText: badgeAdminText ?? this.badgeAdminText,
      badgeFacultyBg: badgeFacultyBg ?? this.badgeFacultyBg,
      badgeFacultyText: badgeFacultyText ?? this.badgeFacultyText,
      announcementBg: announcementBg ?? this.announcementBg,
      announcementBorder: announcementBorder ?? this.announcementBorder,
      adminPostBg: adminPostBg ?? this.adminPostBg,
      adminPostBorder: adminPostBorder ?? this.adminPostBorder,
      primaryAccent: primaryAccent ?? this.primaryAccent,
      onPrimaryAccent: onPrimaryAccent ?? this.onPrimaryAccent,
      successColor: successColor ?? this.successColor,
      categoryJob: categoryJob ?? this.categoryJob,
      categoryInternship: categoryInternship ?? this.categoryInternship,
      categoryAnnouncement: categoryAnnouncement ?? this.categoryAnnouncement,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      bgColor: Color.lerp(bgColor, other.bgColor, t)!,
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      badgeAlumniBg: Color.lerp(badgeAlumniBg, other.badgeAlumniBg, t)!,
      badgeAlumniText: Color.lerp(badgeAlumniText, other.badgeAlumniText, t)!,
      badgeStudentBg: Color.lerp(badgeStudentBg, other.badgeStudentBg, t)!,
      badgeStudentText: Color.lerp(
        badgeStudentText,
        other.badgeStudentText,
        t,
      )!,
      badgeAdminBg: Color.lerp(badgeAdminBg, other.badgeAdminBg, t)!,
      badgeAdminText: Color.lerp(badgeAdminText, other.badgeAdminText, t)!,
      badgeFacultyBg: Color.lerp(badgeFacultyBg, other.badgeFacultyBg, t)!,
      badgeFacultyText: Color.lerp(
        badgeFacultyText,
        other.badgeFacultyText,
        t,
      )!,
      announcementBg: Color.lerp(announcementBg, other.announcementBg, t)!,
      announcementBorder: Color.lerp(
        announcementBorder,
        other.announcementBorder,
        t,
      )!,
      adminPostBg: Color.lerp(adminPostBg, other.adminPostBg, t)!,
      adminPostBorder: Color.lerp(adminPostBorder, other.adminPostBorder, t)!,
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t)!,
      onPrimaryAccent: Color.lerp(onPrimaryAccent, other.onPrimaryAccent, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      categoryJob: Color.lerp(categoryJob, other.categoryJob, t)!,
      categoryInternship: Color.lerp(
        categoryInternship,
        other.categoryInternship,
        t,
      )!,
      categoryAnnouncement: Color.lerp(
        categoryAnnouncement,
        other.categoryAnnouncement,
        t,
      )!,
    );
  }

  // DARK THEME
  static const AppColors darkTheme = AppColors(
    bgColor: Color(0xff141413), // Claude dark background
    cardColor: Color(0xff1E1E1C), // Neutral dark card surface
    borderColor: Color(0xff2C2C29), // Subtle grey border
    primaryText: Color(0xffF7F7F5), // Clean soft white text
    secondaryText: Color(0xffA1A1A0), // Muted secondary grey text

    badgeAlumniBg: Color(0xFF14532D),
    badgeAlumniText: Color(0xFF4ADE80),
    badgeStudentBg: Color(0xFF581C87),
    badgeStudentText: Color(0xFFD8B4FE),
    badgeAdminBg: Color(0xFF1E3A8A),
    badgeAdminText: Color(0xFF93C5FD),
    badgeFacultyBg: Color(0xFF78350F),
    badgeFacultyText: Color(0xFFFCD34D),

    announcementBg: Color(0xFF452B0F),
    announcementBorder: Color(0xFF78350F),
    adminPostBg: Color(0xFF0F172A),
    adminPostBorder: Color(0xFF1E3A8A),

    primaryAccent: Color(0xFF3B82F6),
    onPrimaryAccent: Color(0xFFFFFFFF),
    successColor: Color(0xFF22C55E),
    categoryJob: Color(0xFF10B981),
    categoryInternship: Color(0xFF8B5CF6),
    categoryAnnouncement: Color(0xFFF59E0B),
  );

  // LIGHT THEME
  static const AppColors lightTheme = AppColors(
    bgColor: Color(0xffF5F5F3), // Warm off-white background
    cardColor: Color(0xffFFFFFF), // Pure white card surface
    borderColor: Color(0xffE0E0DE), // Soft grey border
    primaryText: Color(0xff181817), // Deep near-black text
    secondaryText: Color(0xff6B6B6A), // Muted dark grey secondary text

    badgeAlumniBg: Color(0xFFDCFCE7),
    badgeAlumniText: Color(0xFF166534),
    badgeStudentBg: Color(0xFFF3E8FF),
    badgeStudentText: Color(0xFF6B21A8),
    badgeAdminBg: Color(0xFFDBEAFE),
    badgeAdminText: Color(0xFF1E40AF),
    badgeFacultyBg: Color(0xFFFEF3C7),
    badgeFacultyText: Color(0xFF92400E),

    announcementBg: Color(0xFFFFF7ED),
    announcementBorder: Color(0xFFFFEDD5),
    adminPostBg: Color(0xFFEFF6FF),
    adminPostBorder: Color(0xFFBFDBFE),

    primaryAccent: Color(0xFF2563EB),
    onPrimaryAccent: Color(0xFFFFFFFF),
    successColor: Color(0xFF16A34A),
    categoryJob: Color(0xFF10B981),
    categoryInternship: Color(0xFF8B5CF6),
    categoryAnnouncement: Color(0xFFF59E0B),
  );

  // ACCESSOR
  static AppColors of(BuildContext context) {
    final extension = Theme.of(context).extension<AppColors>();
    if (extension != null) return extension;
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }
}
