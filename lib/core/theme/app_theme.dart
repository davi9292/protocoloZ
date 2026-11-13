import 'package:flutter/material.dart';

class ZColors {
  static const background = Color(0xFF090D0B);
  static const surface = Color(0xFF141B17);
  static const surface2 = Color(0xFF1D2821);
  static const green = Color(0xFF9DBB73);
  static const greenDark = Color(0xFF526B3E);
  static const red = Color(0xFFE05252);
  static const muted = Color(0xFF91A095);
  static const line = Color(0xFF2B3930);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: ZColors.background,
    colorScheme: const ColorScheme.dark(
      primary: ZColors.green,
      secondary: ZColors.greenDark,
      surface: ZColors.surface,
      error: ZColors.red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: ZColors.background,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: ZColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: ZColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ZColors.surface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ZColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ZColors.line),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ZColors.green,
        foregroundColor: ZColors.background,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: ZColors.surface,
      indicatorColor: ZColors.surface2,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    useMaterial3: true,
  );
}
