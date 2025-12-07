import 'package:flutter_test/flutter_test.dart';
import 'package:ifs_parts_flutter/models/card_data.dart';
import 'package:ifs_parts_flutter/models/question.dart';

void main() {
  group('CardData Model', () {
    test('should create a card with image and questions', () {
      const cardData = CardData(
        imageAsset: 'assets/images/card_01.png',
        questions: [
          Question(id: 'Q1', text: 'Question 1', type: 'text'),
          Question(id: 'Q2', text: 'Question 2', type: 'text'),
        ],
      );

      expect(cardData.imageAsset, 'assets/images/card_01.png');
      expect(cardData.questions.length, 2);
      expect(cardData.questions[0].text, 'Question 1');
    });

    test('should create a copy with modified fields', () {
      const original = CardData(
        imageAsset: 'assets/images/card_01.png',
        questions: [
          Question(id: 'Q1', text: 'Original question', type: 'text'),
        ],
      );

      final modified = original.copyWith(
        imageAsset: 'assets/images/card_02.png',
      );

      expect(modified.imageAsset, 'assets/images/card_02.png');
      expect(modified.questions, original.questions);
      expect(original.imageAsset, 'assets/images/card_01.png');
    });

    test('should support equality comparison', () {
      const card1 = CardData(
        imageAsset: 'assets/images/card_01.png',
        questions: [
          Question(id: 'Q1', text: 'Question 1', type: 'text'),
        ],
      );

      const card2 = CardData(
        imageAsset: 'assets/images/card_01.png',
        questions: [
          Question(id: 'Q1', text: 'Question 1', type: 'text'),
        ],
      );

      const card3 = CardData(
        imageAsset: 'assets/images/card_02.png',
        questions: [
          Question(id: 'Q1', text: 'Question 1', type: 'text'),
        ],
      );

      expect(card1, equals(card2));
      expect(card1, isNot(equals(card3)));
    });

    test('should have consistent hashCode for equal objects', () {
      const card1 = CardData(
        imageAsset: 'assets/images/card_01.png',
        questions: [
          Question(id: 'Q1', text: 'Question 1', type: 'text'),
        ],
      );

      const card2 = CardData(
        imageAsset: 'assets/images/card_01.png',
        questions: [
          Question(id: 'Q1', text: 'Question 1', type: 'text'),
        ],
      );

      expect(card1.hashCode, equals(card2.hashCode));
    });

    test('should have meaningful toString', () {
      const cardData = CardData(
        imageAsset: 'assets/images/card_01.png',
        questions: [
          Question(id: 'Q1', text: 'Question 1', type: 'text'),
          Question(id: 'Q2', text: 'Question 2', type: 'text'),
        ],
      );

      final string = cardData.toString();
      expect(string, contains('card_01.png'));
      expect(string, contains('2 items'));
    });
  });
}
