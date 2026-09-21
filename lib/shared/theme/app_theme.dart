import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';
import 'app_sizes.dart';
import 'glass_tokens.dart';

ThemeData buildAppTheme() {
  final baseScheme = ColorScheme.light(
    primary: AppColors.secondColor,
    onPrimary: AppColors.surface,
    secondary: AppColors.appColor,
    onSecondary: AppColors.secondColor,
    tertiary: AppColors.thirdColor,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerHighest: AppColors.thirdColor.withValues(alpha: 0.35),
    error: AppColors.error,
    onError: AppColors.onError,
    outline: AppColors.borderSubtle,
  );

  return ThemeData(
    fontFamily: AppFonts.family,
    colorScheme: baseScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.surface,
    cardColor: Colors.white,
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GlassTokens.radiusSheet),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.92),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GlassTokens.radiusSheet),
        ),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      },
    ),

    appBarTheme: AppBarTheme(
      centerTitle: true,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.transparent,
      foregroundColor: AppColors.secondColor,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: AppFonts.family,
        fontSize: AppSizes.fontTitle,
        fontWeight: FontWeight.w600,
        color: AppColors.secondColor,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.secondColor,
        foregroundColor: AppColors.surface,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.spaceBase,
          horizontal: AppSizes.space2xl,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        textStyle: const TextStyle(
          fontFamily: AppFonts.family,
          fontSize: AppSizes.fontBody,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.secondColor,
        textStyle: const TextStyle(
          fontFamily: AppFonts.family,
          fontSize: AppSizes.fontLabel,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.secondColor,
        side: BorderSide(color: AppColors.borderSubtle, width: 1.5),
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.spaceBase,
          horizontal: AppSizes.space2xl,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        textStyle: const TextStyle(
          fontFamily: AppFonts.family,
          fontSize: AppSizes.fontBody,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.thirdColor.withValues(alpha: 0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide.none,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        fontFamily: AppFonts.family,
        fontSize: AppSizes.fontBody,
      ),
      bodyMedium: TextStyle(
        fontFamily: AppFonts.family,
        fontSize: AppSizes.fontLabel,
      ),
      titleLarge: TextStyle(
        fontFamily: AppFonts.family,
        fontSize: AppSizes.fontTitle,
      ),
      headlineSmall: TextStyle(
        fontFamily: AppFonts.family,
        fontSize: AppSizes.fontHeadline,
      ),
    ),
  );
}

ThemeData buildAppDarkTheme() {
  final baseScheme = ColorScheme.dark(
    primary: AppColors.appColor,
    onPrimary: AppColors.onSurface,
    secondary: AppColors.thirdColor,
    onSecondary: AppColors.onSurface,
    tertiary: AppColors.secondColor,
    surface: const Color(0xFF121A20),
    onSurface: AppColors.surface,
    surfaceContainerHighest: const Color(0xFF243038),
    error: AppColors.error,
    onError: AppColors.onError,
    outline: AppColors.borderSubtle,
  );

  return ThemeData(
    fontFamily: AppFonts.family,
    colorScheme: baseScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: baseScheme.surface,
    cardColor: const Color(0xFF1E2B35),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1E2B35).withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GlassTokens.radiusSheet),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: const Color(0xFF1E2B35).withValues(alpha: 0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GlassTokens.radiusSheet),
        ),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.transparent,
      foregroundColor: AppColors.appColor,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: AppFonts.family,
        fontSize: AppSizes.fontTitle,
        fontWeight: FontWeight.w600,
        color: AppColors.appColor,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.appColor,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.spaceBase,
          horizontal: AppSizes.space2xl,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        textStyle: const TextStyle(
          fontFamily: AppFonts.family,
          fontSize: AppSizes.fontBody,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.appColor,
        textStyle: const TextStyle(
          fontFamily: AppFonts.family,
          fontSize: AppSizes.fontLabel,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.appColor,
        side: BorderSide(color: AppColors.borderSubtle, width: 1.5),
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.spaceBase,
          horizontal: AppSizes.space2xl,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        textStyle: const TextStyle(
          fontFamily: AppFonts.family,
          fontSize: AppSizes.fontBody,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: baseScheme.surfaceContainerHighest.withValues(alpha: 0.65),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide.none,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: baseScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        fontFamily: AppFonts.family,
        fontSize: AppSizes.fontBody,
        color: baseScheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: AppFonts.family,
        fontSize: AppSizes.fontLabel,
        color: baseScheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontFamily: AppFonts.family,
        fontSize: AppSizes.fontTitle,
        color: baseScheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontFamily: AppFonts.family,
        fontSize: AppSizes.fontHeadline,
        color: baseScheme.onSurface,
      ),
    ),
  );
}
