// File: lib/config/theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorSchemeSeed: Colors.blueAccent,
    useMaterial3: true,
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorSchemeSeed: Colors.blueAccent,
    useMaterial3: true,
  );
}
