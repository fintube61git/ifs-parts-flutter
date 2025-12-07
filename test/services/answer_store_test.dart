import 'package:flutter_test/flutter_test.dart';
import 'package:ifs_parts_flutter/services/answer_store.dart';

void main() {
  group('AnswerStore', () {
    setUp(() {
      // Reset the store before each test by clearing internal data
      // Note: This is a limitation since AnswerStore is a singleton
      // In a production app, consider making it injectable for testability
    });

    test('should be a singleton', () {
      final instance1 = AnswerStore.instance;
      final instance2 = AnswerStore.instance;

      expect(instance1, same(instance2));
    });

    test('should store and retrieve text answers', () {
      final store = AnswerStore.instance;

      store.setText(0, 0, 'My answer');

      expect(store.getText(0, 0), 'My answer');
    });

    test('should return empty string for non-existent text answer', () {
      final store = AnswerStore.instance;

      expect(store.getText(99, 99), '');
    });

    test('should store and retrieve checkbox selections', () {
      final store = AnswerStore.instance;

      store.toggle(0, 0, 'Option A', true);
      store.toggle(0, 0, 'Option B', true);

      final checked = store.getChecked(0, 0);
      expect(checked, contains('Option A'));
      expect(checked, contains('Option B'));
      expect(checked.length, 2);
    });

    test('should toggle checkbox selection off', () {
      final store = AnswerStore.instance;

      store.toggle(0, 0, 'Option A', true);
      store.toggle(0, 0, 'Option A', false);

      final checked = store.getChecked(0, 0);
      expect(checked, isEmpty);
    });

    test('should return empty set for non-existent checkbox answer', () {
      final store = AnswerStore.instance;

      expect(store.getChecked(99, 99), isEmpty);
    });

    test('should correctly count answered cards', () {
      final store = AnswerStore.instance;

      store.setText(0, 0, 'Answer 1');
      store.setText(1, 0, 'Answer 2');
      store.setText(1, 1, 'Answer 3');

      final count = store.answeredCardCount(99);
      expect(count, 2); // Cards 0 and 1 have answers
    });

    test('should not count cards with empty answers', () {
      final store = AnswerStore.instance;

      store.setText(0, 0, '');
      store.setText(1, 0, '   ');

      final count = store.answeredCardCount(99);
      expect(count, 0);
    });

    test('should detect if card has any answer', () {
      final store = AnswerStore.instance;

      store.setText(0, 0, 'Some answer');

      expect(store.cardHasAnyAnswer(0), isTrue);
      expect(store.cardHasAnyAnswer(1), isFalse);
    });

    test('should handle multiple questions per card', () {
      final store = AnswerStore.instance;

      store.setText(0, 0, 'Answer Q1');
      store.setText(0, 1, 'Answer Q2');
      store.setText(0, 2, 'Answer Q3');

      expect(store.getText(0, 0), 'Answer Q1');
      expect(store.getText(0, 1), 'Answer Q2');
      expect(store.getText(0, 2), 'Answer Q3');
      expect(store.cardHasAnyAnswer(0), isTrue);
    });

    test('should overwrite existing text answer', () {
      final store = AnswerStore.instance;

      store.setText(0, 0, 'First answer');
      store.setText(0, 0, 'Updated answer');

      expect(store.getText(0, 0), 'Updated answer');
    });
  });
}
