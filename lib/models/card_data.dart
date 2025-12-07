import 'question.dart';

/// One card: its image asset and its list of questions.
class CardData {
  final String imageAsset;
  final List<Question> questions;

  const CardData({
    required this.imageAsset,
    required this.questions,
  });

  /// Create a copy with modified fields
  CardData copyWith({
    String? imageAsset,
    List<Question>? questions,
  }) {
    return CardData(
      imageAsset: imageAsset ?? this.imageAsset,
      questions: questions ?? this.questions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CardData &&
        other.imageAsset == imageAsset &&
        _listEquals(other.questions, questions);
  }

  @override
  int get hashCode {
    return Object.hash(imageAsset, Object.hashAll(questions));
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'CardData(imageAsset: $imageAsset, questions: ${questions.length} items)';
  }
}
