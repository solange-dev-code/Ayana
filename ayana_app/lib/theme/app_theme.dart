import 'package:flutter/material.dart';

/// Palette AYANA « refonte 2026 » — identité prune & sauge.
///
/// Couleurs de marque :
///   principal  → prune #4B2747
///   secondaire → sauge #8FA690
/// Sur fond crème (#FDF8F2). Les accents (rose poudré, aubergine, terracotta)
/// déclinent la palette par teinte pour différencier les rubriques.
class AppColors {
  AppColors._();

  // Marque (principal & secondaire)
  static const plum = Color(0xFF4B2747); // principal
  static const plumDeep = Color(0xFF3A1C38);
  static const plumLight = Color(0xFFF1E9F0);
  static const sage = Color(0xFF8FA690); // secondaire
  static const sageDeep = Color(0xFF697F6E);
  static const sageLight = Color(0xFFE9F0EA);
  static const cream = Color(0xFFFDF8F2);

  // Accents de rubriques (déclinaisons de la marque)
  static const rose = Color(0xFFB24E6E);
  static const roseDeep = Color(0xFF8E3F5C);
  static const roseLight = Color(0xFFF8E9EE);
  static const aubergine = Color(0xFF6E4F8F);
  static const aubergineDeep = Color(0xFF54396E);
  static const aubergineLight = Color(0xFFF0EAF6);
  static const terracotta = Color(0xFFBE6A57);
  static const terracottaDeep = Color(0xFF9C5140);
  static const terracottaLight = Color(0xFFF8ECE6);

  // Thème clair naturel
  static const background = Color(0xFFFAF6F1); // crème doux
  static const surface = Color(0xFFFFFFFF);
  static const surfaceHigh = Color(0xFFF4EEE8);
  static const border = Color(0xFFEDE5DC);
  static const borderLight = Color(0xFFE0D6CB);

  // Textes
  static const textPrimary = Color(0xFF2E2430);
  static const textSecondary = Color(0xFF6F6570);
  static const textMuted = Color(0xFFA79CA3);

  // États
  static const successBg = Color(0xFFE9F2EA);
  static const successText = Color(0xFF5E8B68);
  static const dangerBg = Color(0xFFFBEDEA);
  static const dangerText = Color(0xFFB4523F);
}

/* ------------------------------------------------------------------ */
/* Dégradés (adoucis)                                                  */
/* ------------------------------------------------------------------ */

/// Dégradé signature des boutons (prune principal).
LinearGradient brandGradient() => const LinearGradient(
      colors: [AppColors.plum, AppColors.plumDeep],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

LinearGradient roseGradient() => const LinearGradient(
      colors: [AppColors.rose, AppColors.roseDeep],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

/// Dégradé secondaire (sauge).
LinearGradient sageGradient() => const LinearGradient(
      colors: [AppColors.sage, AppColors.sageDeep],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

LinearGradient violetGradient() => const LinearGradient(
      colors: [AppColors.aubergine, AppColors.aubergineDeep],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

LinearGradient coralGradient() => const LinearGradient(
      colors: [AppColors.terracotta, AppColors.terracottaDeep],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

/* ------------------------------------------------------------------ */
/* Thème Material                                                      */
/* ------------------------------------------------------------------ */

ThemeData ayanaTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: AppColors.plum,
    brightness: Brightness.light,
    primary: AppColors.plum,
    secondary: AppColors.sage,
    surface: AppColors.surface,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.plum,
          width: 1.4,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.plum,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerColor: AppColors.border,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
      titleMedium: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textSecondary, height: 1.35),
      bodySmall: TextStyle(color: AppColors.textMuted),
    ),
  );
}