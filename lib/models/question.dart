/// Question model (supports text and checkbox)
class Question {
  final String id;           // stable key (e.g., "Q1" or "Self_Check")
  final String text;         // prompt to display
  final String type;         // "text" | "checkbox"
  final List<String> options; // for checkbox only

  const Question({
    required this.id,
    required this.text,
    required this.type,
    this.options = const [],
  });

  /// Create a copy with modified fields
  Question copyWith({
    String? id,
    String? text,
    String? type,
    List<String>? options,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      options: options ?? this.options,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Question &&
        other.id == id &&
        other.text == text &&
        other.type == type &&
        _listEquals(other.options, options);
  }

  @override
  int get hashCode {
    return Object.hash(id, text, type, Object.hashAll(options));
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
    return 'Question(id: $id, text: $text, type: $type, options: $options)';
  }
}
