import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ifs_parts_flutter/controllers/theme_controller.dart';

void main() {
  group('ThemeController', () {
    test('should initialize with system theme mode', () {
      final controller = ThemeController();

      expect(controller.mode, ThemeMode.system);
    });

    test('should toggle from system to dark', () {
      final controller = ThemeController();

      controller.toggle();

      expect(controller.mode, ThemeMode.dark);
    });

    test('should toggle from dark to light', () {
      final controller = ThemeController();
      controller.toggle(); // system -> dark

      controller.toggle();

      expect(controller.mode, ThemeMode.light);
    });

    test('should toggle from light back to dark', () {
      final controller = ThemeController();
      controller.toggle(); // system -> dark
      controller.toggle(); // dark -> light

      controller.toggle();

      expect(controller.mode, ThemeMode.dark);
    });

    test('should notify listeners on toggle', () {
      final controller = ThemeController();
      var notified = false;
      controller.addListener(() {
        notified = true;
      });

      controller.toggle();

      expect(notified, isTrue);
    });
  });
}
