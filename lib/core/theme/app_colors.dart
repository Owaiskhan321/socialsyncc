import 'package:flutter/material.dart';

/// SocialSyncc design tokens — teal / slate brand palette.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF0D9488); // accent
  static const Color primaryDark = Color(0xFF0F766E); // accentDark
  static const Color primaryDeep = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color accent = Color(0xFFCCFBF1); // accentLight

  // Surfaces
  static const Color background = Color(0xFFF8FAFC); // bg
  static const Color backgroundSecondary = Color(0xFFF0FDFA); // surface
  static const Color surface = Color(0xFFF0FDFA);

  // Ink / muted
  static const Color gray50 = Color(0xFFF8FAFC);
  static const Color gray100 = Color(0xFFF0FDFA);
  static const Color gray200 = Color(0xFFE2E8F0);
  static const Color gray300 = Color(0xFFCBD5E1);
  static const Color gray400 = Color(0xFF94A3B8);
  static const Color gray500 = Color(0xFF64748B); // muted
  static const Color gray700 = Color(0xFF334155);
  static const Color gray800 = Color(0xFF1E293B);
  static const Color gray900 = Color(0xFF0F172A); // ink

  static const Color success = Color(0xFF22C55E);
  static const Color successBg = Color(0xFFF0FDF4);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFEF2F2);

  static const Color border = Color(0x140F172A); // rgba(15,23,42,0.08)

  // Soft brand tints (legacy names used across UI)
  static const Color blue50 = Color(0xFFCCFBF1);
  static const Color blue100 = Color(0xFF99F6E4);
  static const Color blue200 = Color(0xFF5EEAD4);
  static const Color green50 = Color(0xFFF0FDF4);
  static const Color green100 = Color(0xFFDCFCE7);
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red100 = Color(0xFFFEE2E2);
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color purple50 = Color(0xFFF0FDFA);
  static const Color purple = Color(0xFF0F766E);
  static const Color emerald = Color(0xFF0D9488);
  static const Color emeraldBg = Color(0xFFCCFBF1);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}
