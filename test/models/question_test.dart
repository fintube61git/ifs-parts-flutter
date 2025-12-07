import 'package:flutter_test/flutter_test.dart';
import 'package:ifs_parts_flutter/models/question.dart';

void main() {
  group('Question Model', () {
    test('should create a text question', () {
      const question = Question(
        id: 'Q1',
        text: 'What is your name?',
        type: 'text',
      );

      expect(question.id, 'Q1');
      expect(question.text, 'What is your name?');
      expect(question.type, 'text');
      expect(question.options, isEmpty);
    });

    test('should create a checkbox question with options', () {
      const question = Question(
        id: 'Q2',
        text: 'Select your interests',
        type: 'checkbox',
        options: ['Reading', 'Writing', 'Coding'],
      );

      expect(question.id, 'Q2');
      expect(question.text, 'Select your interests');
      expect(question.type, 'checkbox');
      expect(question.options, ['Reading', 'Writing', 'Coding']);
    });

    test('should create a copy with modified fields', () {
      const question = Question(
        id: 'Q1',
        text: 'Original text',
        type: 'text',
      );

      final modified = question.copyWith(text: 'Modified text');

      expect(modified.id, 'Q1');
      expect(modified.text, 'Modified text');
      expect(modified.type, 'text');
      expect(question.text, 'Original text'); // Original unchanged
    });

    test('should support equality comparison', () {
      const question1 = Question(
        id: 'Q1',
        text: 'Test question',
        type: 'text',
      );

      const question2 = Question(
        id: 'Q1',
        text: 'Test question',
        type: 'text',
      );

      const question3 = Question(
        id: 'Q2',
        text: 'Different question',
        type: 'text',
      );

      expect(question1, equals(question2));
      expect(question1, isNot(equals(question3)));
    });

    test('should have consistent hashCode for equal objects', () {
      const question1 = Question(
        id: 'Q1',
        text: 'Test question',
        type: 'text',
      );

      const question2 = Question(
        id: 'Q1',
        text: 'Test question',
        type: 'text',
      );

      expect(question1.hashCode, equals(question2.hashCode));
    });

    test('should have meaningful toString', () {
      const question = Question(
        id: 'Q1',
        text: 'Test question',
        type: 'text',
      );

      final string = question.toString();
      expect(string, contains('Q1'));
      expect(string, contains('Test question'));
      expect(string, contains('text'));
    });
  });
}
