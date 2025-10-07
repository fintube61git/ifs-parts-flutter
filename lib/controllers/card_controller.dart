import 'dart:math';
import 'package:flutter/foundation.dart';

class CardController extends ChangeNotifier {
  final int total;
  final List<int> _shuffledOrder;
  int _currentIndex;

  // Maps shuffled position → original card index (0-based)
  int get originalCardIndex => _shuffledOrder[_currentIndex];

  // Human-readable position (1-based, for UI counter)
  int get displayIndexOneBased => _currentIndex + 1;

  CardController({required this.total, int? seed})
      : assert(total >= 0),
        _shuffledOrder = total <= 1
            ? List<int>.generate(total, (i) => i)
            : _generateShuffledOrder(total, seed),
        _currentIndex = 0 {
    if (total == 0) return;
  }

  static List<int> _generateShuffledOrder(int total, int? seed) {
    final list = List<int>.generate(total, (i) => i);
    final random = seed != null ? Random(seed) : Random();
    for (var i = list.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
    return list;
  }

  // Always allow navigation if more than 1 card
  bool get canGoBack => total > 1;
  bool get canGoForward => total > 1;

  void next() {
    if (total <= 1) return;
    _currentIndex = (_currentIndex + 1) % total;
    notifyListeners();
  }

  void prev() {
    if (total <= 1) return;
    _currentIndex = (_currentIndex - 1 + total) % total;
    notifyListeners();
  }

  void jumpTo(int shuffledPosition) {
    if (total == 0 || shuffledPosition < 0 || shuffledPosition >= total) return;
    if (shuffledPosition == _currentIndex) return;
    _currentIndex = shuffledPosition;
    notifyListeners();
  }

  // For answers: always use originalCardIndex (0-based)
  // Example: AnswerStore.setText(originalCardIndex, questionIndex, value)
}