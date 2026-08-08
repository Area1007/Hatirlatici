import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark theme
  static const Color darkBackground = Color(0xFF0D111A);
  static const Color darkSurface = Color(0xFF1B202A);
  static const Color darkSurfaceAlt = Color(0xFF292E38);
  static const Color darkBorder = Color(0xFF343B47);

  static const Color darkTextPrimary = Color(0xFFF2F4F8);
  static const Color darkTextSecondary = Color(0xFFB7BECA);
  static const Color darkTextMuted = Color(0xFF7F8794);

  // Light theme
  static const Color lightBackground = Color(0xFFF4F6FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFE9EDF4);
  static const Color lightBorder = Color(0xFFD9DEE8);

  static const Color lightTextPrimary = Color(0xFF161A22);
  static const Color lightTextSecondary = Color(0xFF5F6673);
  static const Color lightTextMuted = Color(0xFF8B93A1);

  // Accent colors
  static const Color primary = Color(0xFF4C8DFF);
  static const Color primaryLight = Color(0xFFA9C5FF);
  static const Color primaryDark = Color(0xFF1E5FC7);

  static const Color overdue = Color(0xFFE34747);
  static const Color overdueDark = Color(0xFF7D1118);

  static const Color highPriority = Color(0xFFF39A3A);
  static const Color completed = Color(0xFF38B873);
  static const Color warning = Color(0xFFFFB547);

  static const Color dividerDark = Color(0xFF303641);
  static const Color dividerLight = Color(0xFFDCE1E9);

  static Color background(Brightness brightness) =>
      brightness == Brightness.dark ? darkBackground : lightBackground;

  static Color surface(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurface : lightSurface;

  static Color surfaceAlt(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurfaceAlt : lightSurfaceAlt;

  static Color border(Brightness brightness) =>
      brightness == Brightness.dark ? darkBorder : lightBorder;

  static Color textPrimary(Brightness brightness) =>
      brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;

  static Color textSecondary(Brightness brightness) =>
      brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary;

  static Color textMuted(Brightness brightness) =>
      brightness == Brightness.dark ? darkTextMuted : lightTextMuted;
}