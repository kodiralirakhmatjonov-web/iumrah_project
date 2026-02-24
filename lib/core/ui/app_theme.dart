import 'package:flutter/material.dart';
import 'app_ui.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppUI.font,
      scaffoldBackgroundColor: AppUI.bg,
      colorScheme: ColorScheme.fromSeed(seedColor: AppUI.black),
    );
  }
}
