import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFF0066CC);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
      );
}
