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
    if (other is! CardData) return false;
    if (other.imageAsset != imageAsset) return false;
    if (other.questions.length != questions.length) return false;
    for (var i = 0; i < questions.length; i++) {
      if (other.questions[i] != questions[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(imageAsset, Object.hashAll(questions));
  }

  @override
  String toString() {
    return 'CardData(imageAsset: $imageAsset, questions: ${questions.length} items)';
  }
}
