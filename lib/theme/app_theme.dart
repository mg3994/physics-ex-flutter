import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF0B0F19),
      primaryColor: const Color(0xFF00F0FF),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00F0FF),
        secondary: Color(0xFFFF0055),
        surface: Color(0xFF161B26),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B0F19),
        elevation: 0,
      ),
    );
  }
}
