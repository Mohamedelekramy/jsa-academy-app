import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ألوان تطبيق JSA
class AppColors {
  static const navyDeep = Color(0xFF050F2B);
  static const navy = Color(0xFF0A1F4D);
  static const navyLight = Color(0xFF123A7A);

  static const gold = Color(0xFFF0B429);
  static const goldLight = Color(0xFFFFD466);

  static const textMain = Colors.white;
  static const textSoft = Color(0xFFB9C6E4);

  static const glass = Color(0x1AFFFFFF);
  static const glassBorder = Color(0x33FFFFFF);

  // ألوان الأندية
  static const kids = Color(0xFF2D8CFF);
  static const men = Color(0xFFF0B429);
  static const women = Color(0xFFB4408F);
  static const rehab = Color(0xFF1FA67A);

  static const success = Color(0xFF2ECC71);
  static const danger = Color(0xFFFF5A5F);
}

/// التدرجات
class AppGradients {
  static const background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.navyLight, AppColors.navy, AppColors.navyDeep],
  );

  static const gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.goldLight, AppColors.gold],
  );
}

/// ثيم التطبيق
ThemeData buildAppTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);

  final textTheme = GoogleFonts.cairoTextTheme(base.textTheme).apply(
    bodyColor: AppColors.textMain,
    displayColor: AppColors.textMain,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.navyDeep,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      secondary: AppColors.goldLight,
      surface: AppColors.navy,
      onPrimary: AppColors.navyDeep,
      error: AppColors.danger,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.glass,
      hintStyle: GoogleFonts.cairo(color: AppColors.textSoft),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
    ),
  );
}