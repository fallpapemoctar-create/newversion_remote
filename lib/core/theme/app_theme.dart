import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors tuned from the Figma Make mockups
  // DSFR – Bleu Marianne
  static const Color primary = Color(0xFF000091);
  static const Color primaryLight = Color(0xFFCACEFB);
  static const Color primarySoft = Color(0xFFE5E6FA);

  // Semantic status colors (DSFR)
  static const Color statusDraftBg   = Color(0xFFF3F4F6);
  static const Color statusDraftFg   = Color(0xFF6B7280);
  static const Color statusSentBg    = Color(0xFFEFF6FF);
  static const Color statusSentFg    = Color(0xFF1D4ED8);
  static const Color statusAcceptBg  = Color(0xFFF0FDF4);
  static const Color statusAcceptFg  = Color(0xFF16A34A);
  static const Color statusRejectBg  = Color(0xFFFEF2F2);
  static const Color statusRejectFg  = Color(0xFFDC2626);
  static const Color statusExpiredBg = Color(0xFFFFFBEB);
  static const Color statusExpiredFg = Color(0xFFD97706);
  static const Color statusSpecialBg = Color(0xFFF5F3FF);
  static const Color statusSpecialFg = Color(0xFF7C3AED);
  static const Color statusValidBg   = Color(0xFFECFDF5);
  static const Color statusValidFg   = Color(0xFF065F46);
  static const Color statusLockedBg  = Color(0xFFF9FAFB);
  static const Color statusLockedFg  = Color(0xFF374151);
  static const Color background = Color(0xFFF3F4F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF7F8FC);
  static const Color border = Color(0xFFE5E7EF);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color sidebarBg = Color(0xFF1E293B);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      surface: background,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: border,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1),
    fontFamily: 'Inter',
  );
}
