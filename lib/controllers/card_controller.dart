import 'package:flutter/foundation.dart';

class CardController extends ChangeNotifier {
  final int total;
  int _index;

  CardController({required this.total, int initialIndex = 0})
      : assert(total >= 0),
        assert(initialIndex >= 0 && initialIndex <= total - 1 || total == 0),
        _index = total == 0 ? 0 : initialIndex;

  int get index => _index;

  bool get canGoBack => total > 0 && _index > 0;
  bool get canGoForward => total > 0 && _index < total - 1;

  void next() {
    if (!canGoForward) return;
    _index += 1;
    notifyListeners();
  }

  void prev() {
    if (!canGoBack) return;
    _index -= 1;
    notifyListeners();
  }

  void jumpTo(int idx) {
    if (idx < 0 || idx >= total) return;
    if (idx == _index) return;
    _index = idx;
    notifyListeners();
  }
}
