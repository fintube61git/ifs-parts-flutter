// lib/controllers/card_controller.dart
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Controls navigation over a deck of `total` cards.
///
/// IMPORTANT DESIGN:
/// - PUBLIC `index` returns the **real card index** (after shuffling).
///   Your UI that builds paths like `card_###.png` will keep working.
/// - `_pos` is the visible position (0..total-1) within the shuffled order.
/// - `_order` is a per-launch randomized permutation of [0..total-1].
///
/// NEW:
/// - `next()` / `prev()` now **wrap** (loop) across the deck.
/// - `position` exposes the visible 0-based position for UI.
/// - `displayIndexOneBased` exposes the human-friendly “X of Y” number.
class CardController extends ChangeNotifier {
  final int total;

  /// Visible position in the shuffled order (0..total-1)
  int _pos;

  /// Shuffled mapping from visible position -> real card index
  late final List<int> _order;

  CardController({required this.total, int initialIndex = 0})
      : assert(total >= 0),
        assert(initialIndex >= 0 && (total == 0 || initialIndex <= total - 1)),
        _pos = (total == 0) ? 0 : initialIndex {
    _buildOrder();
  }

  void _buildOrder() {
    _order = List<int>.generate(total, (i) => i);
    if (_order.length > 1) {
      final seed = DateTime.now().millisecondsSinceEpoch;
      _order.shuffle(Random(seed));
      if (_pos < 0 || _pos >= _order.length) _pos = 0;
    }
  }

  /// PUBLIC: the **real** (shuffled) card index backing the current position.
  int get index => (total == 0) ? 0 : _order[_pos];

  /// PUBLIC: visible position (0..total-1)
  int get position => _pos;

  /// PUBLIC: 1-based number for "Card X of Y" display
  int get displayIndexOneBased => (total == 0) ? 0 : (_pos + 1);

  /// Shuffled order (useful for export to preserve the session order).
  List<int> get orderForExport => List<int>.unmodifiable(_order);

  bool get canGoBack => total > 0;     // loop-enabled: always true if any cards
  bool get canGoForward => total > 0;  // loop-enabled: always true if any cards

  /// Looping next: after the last, go to the first.
  void next() {
    if (total <= 1) return;
    _pos = (_pos + 1) % total;
    notifyListeners();
  }

  /// Looping prev: before the first, go to the last.
  void prev() {
    if (total <= 1) return;
    _pos = (_pos == 0) ? (total - 1) : (_pos - 1);
    notifyListeners();
  }

  /// Jump by **visible position** (0..total-1).
  void jumpTo(int pos) {
    if (pos < 0 || pos >= total) return;
    if (pos == _pos) return;
    _pos = pos;
    notifyListeners();
  }

  /// Optional: rebuild a new shuffled order but keep the same real card visible.
  void reshuffleKeepingCurrent() {
    if (total <= 1) return;
    final currentReal = index;
    _buildOrder();
    final newPos = _order.indexOf(currentReal);
    _pos = (newPos >= 0) ? newPos : 0;
    notifyListeners();
  }
}
