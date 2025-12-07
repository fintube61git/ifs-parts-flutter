/// Singleton store for user answers to card questions.
/// 
/// Stores answers in memory only - they are not persisted between sessions.
/// Supports two answer types:
/// - Text answers (String)
/// - Checkbox answers (Set<String>)
/// 
/// Answers are indexed by card index (0-based) and question index (0-based).
class AnswerStore {
  AnswerStore._();
  static final AnswerStore instance = AnswerStore._();

  // cardIndex -> { questionIndex -> answer(String | Set<String>) }
  final Map<int, Map<int, dynamic>> _store = {};

  /// Get text answer for a card and question. Returns empty string if not set.
  String getText(int card, int q) =>
      (_store[card]?[q] is String) ? (_store[card]![q] as String) : "";

  /// Set text answer for a card and question.
  void setText(int card, int q, String val) {
    final m = _store.putIfAbsent(card, () => {});
    m[q] = val;
  }

  /// Get checked options for a checkbox question. Returns empty set if not set.
  Set<String> getChecked(int card, int q) =>
      (_store[card]?[q] is Set<String>) ? Set<String>.from(_store[card]![q] as Set<String>) : <String>{};

  /// Toggle a checkbox option on or off for a card and question.
  void toggle(int card, int q, String option, bool on) {
    final m = _store.putIfAbsent(card, () => {});
    final current = getChecked(card, q);
    if (on) {
      current.add(option);
    } else {
      current.remove(option);
    }
    m[q] = current;
  }

  bool _isAnswered(dynamic v) {
    if (v == null) return false;
    if (v is String) return v.trim().isNotEmpty;
    if (v is Set) return v.isNotEmpty;
    if (v is List) return v.isNotEmpty;
    return false;
  }

  /// Count how many cards have at least one non-empty answer.
  int answeredCardCount(int totalCards) {
    int count = 0;
    for (var card = 0; card < totalCards; card++) {
      final qs = _store[card];
      if (qs == null) continue;
      if (qs.values.any(_isAnswered)) count++;
    }
    return count;
  }

  /// Check if a specific card has any non-empty answer.
  bool cardHasAnyAnswer(int card) {
    final qs = _store[card];
    if (qs == null) return false;
    for (final v in qs.values) {
      if (_isAnswered(v)) return true;
    }
    return false;
  }
}
