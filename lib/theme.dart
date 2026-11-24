import 'package:flutter/material.dart';

class AppColors {
  static const bgTop = Color(0xFF0B1226);
  static const bgBottom = Color(0xFF161E38);
  static const surface = Color(0xFF1B2440);
  static const accent = Color(0xFF4FC3F7);
  static const accent2 = Color(0xFF7C8CFF);
  static const text = Color(0xFFE8ECF8);
  static const textDim = Color(0xFF93A0C4);
}

const appGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [AppColors.bgTop, AppColors.bgBottom],
);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.dark,
  ).copyWith(surface: AppColors.surface);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bgTop,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.text,
    ),
  );
}
