import 'package:flutter/material.dart';

// The patient-facing app's visual identity: a warm, calm palette (cream +
// sage, one terracotta highlight reserved for primary actions) paired with
// a real typographic system — a display face for the wordmark and headers,
// a highly legible sans for everything else. Kept deliberately different
// from the caregiver dashboard's theme (lib/dashboard/dashboard_theme.dart)
// — that audience scans a screen for data; this one is the patient, and
// needs calm and clarity over visual density.
class AppColors {
  AppColors._();

  static const background = Color(0xFFFBF6EC);
  // A visibly deeper tone than background so cards read as distinct
  // surfaces rather than cream-on-cream.
  static const surface = Color(0xFFF1E8D6);
  static const ink = Color(0xFF33302A);
  static const inkMuted = Color(0xFF79715F);

  static const sage = Color(0xFF8FA98A);
  static const sageDark = Color(0xFF6E8B6A);

  // Reserved for primary CTAs and progress/success states only — kept
  // scarce on purpose so it still reads as "special" wherever it appears.
  static const highlight = Color(0xFFC97B4A);
  // Wrong-answer feedback only. Distinct enough from the highlight to read
  // as "incorrect" rather than just another accented element, but still a
  // muted, warm tone rather than an alarming neon red.
  static const error = Color(0xFFB3483A);
}

class AppTextStyles {
  AppTextStyles._();

  static const _display = 'Baloo2';
  static const _body = 'WorkSans';

  // The "SMRITI" wordmark and other identity moments only — never body text.
  static const wordmark = TextStyle(
    fontFamily: _display,
    fontWeight: FontWeight.w800,
    fontSize: 34,
    color: AppColors.ink,
    height: 1.1,
  );

  // Screen/section titles.
  static const headline = TextStyle(
    fontFamily: _display,
    fontWeight: FontWeight.w700,
    fontSize: 26,
    color: AppColors.ink,
    height: 1.2,
  );

  // Card titles, game names.
  static const title = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    color: AppColors.ink,
    height: 1.3,
  );

  // Descriptions, instructions, supporting text. Minimum ~18sp per the
  // elderly-first requirement.
  static const body = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w400,
    fontSize: 18,
    color: AppColors.ink,
    height: 1.45,
  );

  static const bodyMuted = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    color: AppColors.inkMuted,
    height: 1.4,
  );

  // Primary in-game text — questions and prompts. Noticeably larger than
  // standard body since these are the most important reading moments.
  static const bodyLarge = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w500,
    fontSize: 22,
    color: AppColors.ink,
    height: 1.4,
  );

  // Buttons, nav labels — letter-spacing opened up slightly for clarity.
  static const label = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    color: AppColors.ink,
    letterSpacing: 0.3,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.sage, width: 1.5),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.sage,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.sage,
        secondary: AppColors.highlight,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'WorkSans',
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: AppTextStyles.wordmark,
        headlineLarge: AppTextStyles.headline,
        headlineMedium: AppTextStyles.headline,
        titleLarge: AppTextStyles.title,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.bodyMuted,
        labelLarge: AppTextStyles.label,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Baloo2',
          color: AppColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.highlight,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.highlight.withValues(alpha: 0.35),
          textStyle: AppTextStyles.label.copyWith(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 2,
          shadowColor: AppColors.highlight.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.sageDark,
          textStyle: AppTextStyles.label.copyWith(color: AppColors.sageDark),
          side: const BorderSide(color: AppColors.sage, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.sageDark,
          textStyle: AppTextStyles.label.copyWith(color: AppColors.sageDark),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.sageDark),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: AppTextStyles.headline.copyWith(fontSize: 22),
        contentTextStyle: AppTextStyles.body,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.sageDark, width: 2),
        ),
      ),
    );
  }
}
