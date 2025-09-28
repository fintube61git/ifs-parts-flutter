import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

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
}

/// One card: its image asset and its list of questions.
class CardData {
  final String imageAsset;
  final List<Question> questions;
  const CardData({required this.imageAsset, required this.questions});
}

/// Loads images and questions from assets/ and exposes them to the UI.
class DataService extends ChangeNotifier {
  List<CardData> _cards = const [];
  List<CardData> get cards => _cards;
  int get total => _cards.length;

  Future<void> load() async {
    final imageAssets = await _loadImageAssetList();
    final qModel = await _loadQuestionsModel();

    final out = <CardData>[];
    for (var i = 0; i < imageAssets.length; i++) {
      final image = imageAssets[i];
      final questions = qModel.getForCard(i);
      out.add(CardData(imageAsset: image, questions: questions));
    }
    _cards = out;
    debugPrint('[DataService] Loaded ${_cards.length} cards '
        '(${imageAssets.length} images, questions-model=${qModel.kind})');
    notifyListeners();
  }

  // ---------- internals ----------

  Future<List<String>> _loadImageAssetList() async {
    final manifestRaw = await rootBundle.loadString('AssetManifest.json');
    final dynamic manifest = json.decode(manifestRaw);

    Iterable<String> keys;
    if (manifest is Map && manifest['assets'] is Map) {
      keys = (manifest['assets'] as Map).keys.cast<String>();
    } else if (manifest is Map) {
      keys = manifest.keys.cast<String>();
    } else {
      throw StateError('Unexpected AssetManifest.json format');
    }

    final images = keys
        .where((k) => k.startsWith('assets/images/'))
        .where((k) =>
            k.endsWith('.png') ||
            k.endsWith('.jpg') ||
            k.endsWith('.jpeg') ||
            k.endsWith('.webp'))
        .toList();

    images.sort(_naturalComparePaths);
    return images;
  }

  Future<_QuestionsModel> _loadQuestionsModel() async {
    try {
      final raw = await rootBundle.loadString('assets/questions.json');
      final dynamic any = json.decode(raw);

      // ---- GLOBAL shapes ----
      // A) ["Q1","Q2",...]
      if (any is List && any.isNotEmpty && any.every((e) => e is String)) {
        final list = (any as List<String>)
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        return _QuestionsModel.global(_stringsToQuestions(list));
      }
      // B) [{"text":"..."}, {"id":"Self_Check","text":"...","type":"checkbox","options":[...]}]
      if (any is List &&
          any.isNotEmpty &&
          any.every((e) => e is Map || e is String) &&
          any.any((e) => e is Map)) {
        final looksLikePerCard = any.every((e) =>
            (e is List) ||
            (e is Map && (e.containsKey('questions') || e.containsKey('qs'))));
        if (!looksLikePerCard) {
          final qs = any.map((e) => _toQuestion(e, index: null, qNumber: null)).whereType<Question>().toList();
          return _QuestionsModel.global(qs);
        }
      }
      // C) { "questions": [ ... ] }
      if (any is Map && any['questions'] is List) {
        final rawList = any['questions'] as List;
        final qs = rawList.map((e) => _toQuestion(e, index: null, qNumber: null)).whereType<Question>().toList();
        return _QuestionsModel.global(qs);
      }

      // ---- PER-CARD shapes ----
      // D) [ [ ... ], [ ... ] ] or [ {questions:[...]}, {...} ]
      if (any is List &&
          any.isNotEmpty &&
          any.every((e) => e is List || (e is Map && (e.containsKey('questions') || e.containsKey('qs'))))) {
        final perCard = <List<Question>>[];
        for (var i = 0; i < any.length; i++) {
          final item = any[i];
          final list = _extractQuestions(item, cardIndex: i);
          perCard.add(list);
        }
        return _QuestionsModel.perCard(perCard);
      }
      // E) { "cards": [...] }
      if (any is Map && any['cards'] is List) {
        final src = any['cards'] as List;
        final perCard = <List<Question>>[];
        for (var i = 0; i < src.length; i++) {
          perCard.add(_extractQuestions(src[i], cardIndex: i));
        }
        return _QuestionsModel.perCard(perCard);
      }
      // F) { "1":[...], "2":[...], ... }
      if (any is Map) {
        final entries = any.entries.toList()
          ..sort((a, b) => _tryParseInt(a.key).compareTo(_tryParseInt(b.key)));
        final perCard = <List<Question>>[];
        for (var i = 0; i < entries.length; i++) {
          perCard.add(_extractQuestions(entries[i].value, cardIndex: i));
        }
        return _QuestionsModel.perCard(perCard);
      }

      debugPrint('[DataService] Unknown questions.json shape; using empty global model.');
      return _QuestionsModel.global(const []);
    } catch (e) {
      debugPrint('[DataService] Failed to load assets/questions.json: $e');
      return _QuestionsModel.global(const []);
    }
  }

  static List<Question> _stringsToQuestions(List<String> list) {
    final out = <Question>[];
    for (var i = 0; i < list.length; i++) {
      out.add(Question(id: 'Q${i + 1}', text: list[i], type: 'text'));
    }
    return out;
  }

  static List<Question> _extractQuestions(dynamic node, {required int cardIndex}) {
    if (node == null) return const <Question>[];

    // List of strings or objects
    if (node is List) {
      final out = <Question>[];
      for (var i = 0; i < node.length; i++) {
        final q = _toQuestion(node[i], index: cardIndex, qNumber: i + 1);
        if (q != null) out.add(q);
      }
      return out;
    }

    // Object like { questions:[...] } or a single question object
    if (node is Map) {
      if (node.containsKey('questions')) return _extractQuestions(node['questions'], cardIndex: cardIndex);
      if (node.containsKey('qs')) return _extractQuestions(node['qs'], cardIndex: cardIndex);
      final q = _toQuestion(node, index: cardIndex, qNumber: null);
      return q == null ? const <Question>[] : <Question>[q];
    }

    // Single string
    if (node is String) {
      return <Question>[
        Question(id: 'Q1', text: node.trim(), type: 'text'),
      ];
    }

    return const <Question>[];
  }

  static Question? _toQuestion(dynamic e, {int? index, int? qNumber}) {
    if (e == null) return null;

    if (e is String) {
      return Question(
        id: qNumber == null ? 'Q' : 'Q$qNumber',
        text: e.trim(),
        type: 'text',
      );
    }

    if (e is Map) {
      final rawText = _extractText(e);
      if (rawText.isEmpty) return null;

      final type = (e['type'] is String) ? (e['type'] as String).toLowerCase().trim() : 'text';
      final id = (e['id'] is String && (e['id'] as String).trim().isNotEmpty)
          ? (e['id'] as String).trim()
          : (qNumber == null ? 'Q' : 'Q$qNumber');

      final options = <String>[];
      if (type == 'checkbox' && e['options'] is List) {
        for (final opt in (e['options'] as List)) {
          if (opt is String && opt.trim().isNotEmpty) {
            options.add(opt.trim());
          }
        }
      }

      return Question(id: id, text: rawText, type: type, options: options);
    }

    return null;
  }

  static String _extractText(dynamic q) {
    if (q == null) return '';
    if (q is String) return q.trim();
    if (q is Map) {
      for (final key in const ['text', 'question', 'q', 'label', 'prompt']) {
        final v = q[key];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }
    return '';
  }

  // Natural sort: ..._001.png < ..._010.png
  static int _naturalComparePaths(String a, String b) {
    final na = _lastNumberIn(a);
    final nb = _lastNumberIn(b);
    if (na != null && nb != null) return na.compareTo(nb);
    return a.compareTo(b);
  }

  static int? _lastNumberIn(String s) {
    final m = RegExp(r'(\d+)').allMatches(s);
    if (m.isEmpty) return null;
    return int.tryParse(m.last.group(1)!);
  }

  static int _tryParseInt(String s) => int.tryParse(s) ?? 1 << 30;
}

/// Represents either a single global question list, or per-card lists.
class _QuestionsModel {
  final String kind; // 'global' or 'per-card'
  final List<Question> _global;
  final List<List<Question>> _perCard;

  _QuestionsModel._(this.kind, this._global, this._perCard);

  factory _QuestionsModel.global(List<Question> questions) =>
      _QuestionsModel._('global', questions, const []);

  factory _QuestionsModel.perCard(List<List<Question>> perCard) =>
      _QuestionsModel._('per-card', const [], perCard);

  List<Question> getForCard(int index) {
    if (kind == 'per-card') {
      if (index < _perCard.length) return _perCard[index];
      return const <Question>[];
    }
    return _global;
  }
}
