import 'package:flutter/material.dart';

class AppTheme {
  // 🌤 Light Yellow (soft, not blinding)
  static const Color lightYellow = Color(0xFFFFF8E1);

  // 🌱 Light Green (primary accent)
  static const Color lightGreen = Color(0xFFB7E4C7);

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightYellow,
    colorScheme: ColorScheme.fromSeed(
      seedColor: lightGreen,
      brightness: Brightness.light,
      background: lightYellow,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightGreen,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: ColorScheme.fromSeed(
      seedColor: lightGreen,
      brightness: Brightness.dark,
    ),
  );
}
