import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Define la apariencia institucional de toda la aplicación.
class AppTheme {
  AppTheme._();

  /// Familia tipográfica institucional.
  static const String fontFamily = 'RobotoCondensed';

  /// Tema principal de la aplicación.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Tipografía global.
      fontFamily: fontFamily,

      // Color de fondo institucional.
      scaffoldBackgroundColor: AppColors.backgroundCream,

      // Paleta de colores.
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGuinda,
        primary: AppColors.primaryGuinda,
        secondary: AppColors.secondaryGold,
        surface: AppColors.surfaceWhite,
        error: AppColors.errorRed,
      ),

      // Configuración de las barras superiores.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryGuinda,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),

      // Configuración de los botones principales.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGuinda,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Configuración de los campos de texto.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundCream.withValues(alpha: 0.45),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primaryGuinda,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
      ),
    );
  }
}
