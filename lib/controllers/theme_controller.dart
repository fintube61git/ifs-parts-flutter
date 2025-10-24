// lib/controllers/theme_controller.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeController with ChangeNotifier {
  ThemeMode mode = ThemeMode.system;

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