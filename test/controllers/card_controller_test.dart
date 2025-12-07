import 'package:flutter_test/flutter_test.dart';
import 'package:ifs_parts_flutter/controllers/card_controller.dart';

void main() {
  group('CardController', () {
    test('should initialize with correct defaults', () {
      final controller = CardController(total: 10);

      expect(controller.total, 10);
      expect(controller.displayIndexOneBased, 1);
      expect(controller.originalCardIndex, isNotNull);
    });

    test('should shuffle cards with different seed', () {
      final controller1 = CardController(total: 10, seed: 123);
      final controller2 = CardController(total: 10, seed: 456);

      expect(controller1.originalCardIndex, isNot(equals(controller2.originalCardIndex)));
    });

    test('should use same shuffle with same seed', () {
      final controller1 = CardController(total: 10, seed: 123);
      final controller2 = CardController(total: 10, seed: 123);

      expect(controller1.originalCardIndex, equals(controller2.originalCardIndex));
    });

    test('should navigate forward correctly', () {
      final controller = CardController(total: 5, seed: 42);
      final firstIndex = controller.displayIndexOneBased;

      controller.next();

      expect(controller.displayIndexOneBased, firstIndex + 1);
    });

    test('should navigate backward correctly', () {
      final controller = CardController(total: 5, seed: 42);
      controller.next();
      final currentIndex = controller.displayIndexOneBased;

      controller.prev();

      expect(controller.displayIndexOneBased, currentIndex - 1);
    });

    test('should wrap around when navigating forward from last card', () {
      final controller = CardController(total: 3, seed: 42);

      // Navigate to last card
      controller.next(); // Card 2
      controller.next(); // Card 3

      // Navigate forward again - should wrap to Card 1
      controller.next();

      expect(controller.displayIndexOneBased, 1);
    });

    test('should wrap around when navigating backward from first card', () {
      final controller = CardController(total: 3, seed: 42);

      // At first card, navigate backward - should wrap to last card
      controller.prev();

      expect(controller.displayIndexOneBased, 3);
    });

    test('should allow jump to specific position', () {
      final controller = CardController(total: 10, seed: 42);

      controller.jumpTo(5);

      expect(controller.displayIndexOneBased, 6); // 1-based display
    });

    test('should not jump to invalid position', () {
      final controller = CardController(total: 5, seed: 42);
      final originalIndex = controller.displayIndexOneBased;

      controller.jumpTo(-1);
      expect(controller.displayIndexOneBased, originalIndex);

      controller.jumpTo(5);
      expect(controller.displayIndexOneBased, originalIndex);

      controller.jumpTo(100);
      expect(controller.displayIndexOneBased, originalIndex);
    });

    test('should handle single card correctly', () {
      final controller = CardController(total: 1);

      expect(controller.canGoBack, isFalse);
      expect(controller.canGoForward, isFalse);
      expect(controller.displayIndexOneBased, 1);
    });

    test('should handle zero cards correctly', () {
      final controller = CardController(total: 0);

      expect(controller.total, 0);
    });

    test('should notify listeners on navigation', () {
      final controller = CardController(total: 5, seed: 42);
      var notified = false;
      controller.addListener(() {
        notified = true;
      });

      controller.next();

      expect(notified, isTrue);
    });

    test('should allow navigation for multiple cards', () {
      final controller = CardController(total: 5);

      expect(controller.canGoBack, isTrue);
      expect(controller.canGoForward, isTrue);
    });
  });
}
