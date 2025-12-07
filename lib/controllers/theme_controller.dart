import 'package:flutter/material.dart';

/// Controller for managing application theme mode.
/// 
/// Supports three theme modes:
/// - System: Follow system theme preference
/// - Light: Force light theme
/// - Dark: Force dark theme
/// 
/// The toggle() method cycles through: system -> dark -> light -> dark...
class ThemeController with ChangeNotifier {
  ThemeMode mode = ThemeMode.system;

  /// Toggle between theme modes: system -> dark -> light -> dark
  void toggle() {
    if (mode == ThemeMode.light) {
      mode = ThemeMode.dark;
    } else if (mode == ThemeMode.dark) {
      mode = ThemeMode.light;
    } else {
      mode = ThemeMode.dark;
    }
    notifyListeners();
  }
}