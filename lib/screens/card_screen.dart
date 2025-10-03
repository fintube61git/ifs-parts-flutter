import "dart:convert";
import "dart:io";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:path_provider/path_provider.dart";
import "package:provider/provider.dart";

import "../controllers/card_controller.dart";
import "../controllers/ui_heartbeat.dart";
import "../services/answer_store.dart";
import "../main.dart" show ThemeController, ExportCard, ExportQuestion, buildExportHtmlFrom, buildExportPdfFrom;

/// --------- Default export directory & helpers (Downloads -> Documents) ---------
Future<Directory> _defaultExportDirectory() async {
  try {
    final dir = await getDownloadsDirectory();
    if (dir != null) return dir;
  } catch (_) {}
  try {
    final dir = await getApplicationDocumentsDirectory();
    return dir;
  } catch (_) {
    return Directory.current;
  }
}

String _timestamp() {
  final now = DateTime.now();
  String two(int v) => v.toString().padLeft(2, "0");
  return "${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}";
}

class CardScreen extends StatelessWidget {
  const CardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<UiHeartbeat?>();

    final dynamic ctrl = context.watch<CardController>();

    // Total cards (controller first, fallback)
    final int total = _readInt(() => ctrl.total, orElse: () => _readInt(() => ctrl.totalCards, orElse: () => 75));

    // REAL index (used for assets/answers/export)
    final int idx = _readInt(() => ctrl.index, orElse: () => _readInt(() => ctrl.currentIndex, orElse: () => 0));

    // HUMAN COUNTER (visible position → 1-based for "Card X of Y"), no unnecessary casts
    final int humanIndex = (() {
      try {
        final v = ctrl.displayIndexOneBased;
        if (v is int && v > 0) return v.clamp(1, total);
      } catch (_) {}
      try {
        final v = ctrl.position;
        if (v is int) return (v + 1).clamp(1, total);
      } catch (_) {}
      try {
        final v = ctrl.visibleIndex;
        if (v is int) return (v + 1).clamp(1, total);
      } catch (_) {}
      return (idx + 1).clamp(1, total);
    })();

    // Answer counts (controller first, then AnswerStore)
    final int controllerAnswered = _readInt(
      () => ctrl.answeredCount,
      orElse: () => _readInt(() => ctrl.answeredCardCount, orElse: () => 0),
    );
    final int fallbackAnswered = AnswerStore.instance.answeredCardCount(total);
    final int answeredCount = controllerAnswered + fallbackAnswered;

    // Image path (controller path if provided; else resolver will probe)
    String? imagePath;
    try {
      imagePath = ctrl.currentImagePath();
    } catch (_) {
      try {
        imagePath = ctrl.imagePathForCurrentCard(idx);
      } catch (_) {
        imagePath = null;
      }
    }

    // Questions (controller-provided or from questions.json)
    List<dynamic> questions;
    try {
      questions = List<dynamic>.from(ctrl.currentQuestions());
    } catch (_) {
      try {
        questions = List<dynamic>.from(ctrl.questionsForCard(idx));
      } catch (_) {
        questions = const <dynamic>[];
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("IFS Parts Exploration"),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Toggle light/dark",
            onPressed: () => context.read<ThemeController>().toggle(),
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: "Export",
            icon: const Icon(Icons.ios_share_outlined),
            onSelected: (v) async {
              if (v == "html") {
                await _exportHtml(context, ctrl, total);
              } else if (v == "pdf") {
                await _exportPdf(context, ctrl, total);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: "html", child: Text("Export HTML…")),
              PopupMenuItem(value: "pdf", child: Text("Export PDF…")),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "$answeredCount cards have answers",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: _CardImage(
                              cardIndex: idx, // REAL index drives asset lookup
                              providedAssetPath: imagePath,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 7,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                      child: Column(
                        children: [
                          _NavBar(
                            humanIndex: humanIndex, // COUNTER position
                            total: total,
                            onBack: () {
                              try { ctrl.prev(); return; } catch (_) {}
                              try { ctrl.goPrevCard(); return; } catch (_) {}
                            },
                            onForward: () {
                              try { ctrl.next(); return; } catch (_) {}
                              try { ctrl.goNextCard(); return; } catch (_) {}
                            },
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: _QuestionsArea(
                              ctrl: ctrl,
                              totalCards: total,
                              cardIndex: idx, // REAL index for answers/questions
                              providedQuestions: questions,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static int _readInt(int Function() getter, {required int Function() orElse}) {
    try {
      return getter();
    } catch (_) {
      return orElse();
    }
  }
}

/// ------- Image fallback resolver --------
class _CardImage extends StatelessWidget {
  const _CardImage({required this.cardIndex, required this.providedAssetPath});

  final int cardIndex; // REAL index, 0-based
  final String? providedAssetPath;

  Future<String?> _resolveAsset() async {
    if (providedAssetPath != null && providedAssetPath!.isNotEmpty) {
      try { await rootBundle.load(providedAssetPath!); return providedAssetPath; } catch (_) {}
    }
    final n = cardIndex + 1;
    final z2 = n.toString().padLeft(2, "0");
    final z3 = n.toString().padLeft(3, "0");
    final candidates = <String>[
      "assets/images/$n.png",
      "assets/images/$n.jpg",
      "assets/images/$z2.png",
      "assets/images/$z2.jpg",
      "assets/images/$z3.png",
      "assets/images/$z3.jpg",
      "assets/images/card_$n.png",
      "assets/images/card_$n.jpg",
      "assets/images/card_$z2.png",
      "assets/images/card_$z2.jpg",
      "assets/images/card_$z3.png",
      "assets/images/card_$z3.jpg",
      "assets/images/Card$n.png",
      "assets/images/Card$n.jpg",
      "assets/images/Card$z2.png",
      "assets/images/Card$z2.jpg",
      "assets/images/Card$z3.png",
      "assets/images/Card$z3.jpg",
      "assets/images/image_$n.png",
      "assets/images/image_$n.jpg",
      "assets/images/image_$z2.png",
      "assets/images/image_$z2.jpg",
      "assets/images/image_$z3.png",
      "assets/images/image_$z3.jpg",
    ];
    for (final p in candidates) {
      try { await rootBundle.load(p); return p; } catch (_) {}
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _resolveAsset(),
      builder: (context, snap) {
        final path = snap.data;
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()));
        }
        if (path == null) {
          return const _MissingImageFallback(path: "unknown");
        }
        return Image.asset(path, fit: BoxFit.contain);
      },
    );
  }
}

/// ------- Questions area --------
class _QuestionsArea extends StatefulWidget {
  const _QuestionsArea({
    required this.ctrl,
    required this.totalCards,
    required this.cardIndex,
    required this.providedQuestions,
  });

  final dynamic ctrl;
  final int totalCards;
  final int cardIndex; // REAL index
  final List<dynamic> providedQuestions;

  @override
  State<_QuestionsArea> createState() => _QuestionsAreaState();
}

class _QuestionsAreaState extends State<_QuestionsArea> {
  static List<dynamic>? _questionsCache; // parsed from assets/questions.json

  Future<List<dynamic>> _ensureQuestions() async {
    if (widget.providedQuestions.isNotEmpty) return widget.providedQuestions;

    if (_questionsCache == null) {
      try {
        final raw = await rootBundle.loadString("assets/questions.json");
        final parsed = jsonDecode(raw);
        if (parsed is List) {
          _questionsCache = parsed;
        } else if (parsed is Map && parsed["questions"] is List) {
          _questionsCache = parsed["questions"] as List;
        } else {
          _questionsCache = const <dynamic>[];
        }
      } catch (_) {
        _questionsCache = const <dynamic>[];
      }
    }

    final all = _questionsCache!;
    if (all.isEmpty) return all;

    if (all.length >= (widget.cardIndex + 1) * 7) {
      final start = widget.cardIndex * 7;
      return all.sublist(start, start + 7);
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _ensureQuestions(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final questions = snap.data!;
        return ScrollConfiguration(
          behavior: const ScrollBehavior(),
          child: ListView.builder(
            key: ValueKey<int>(widget.cardIndex),
            primary: false,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            itemCount: questions.length,
            itemBuilder: (context, qIndex) {
              final q = questions[qIndex];

              String qText = "Question ${qIndex + 1}";
              try {
                final t = widget.ctrl.questionText(q);
                if (t is String && t.isNotEmpty) qText = t;
              } catch (_) {
                if (q is Map && q["text"] is String) {
                  qText = q["text"] as String;
                }
              }

              String qType = "text";
              try {
                final t = widget.ctrl.questionType(q);
                if (t is String && t.isNotEmpty) qType = t;
              } catch (_) {
                if (q is Map && q["type"] is String) {
                  qType = q["type"] as String;
                } else if (q is Map && q["options"] is List) {
                  qType = "checkbox";
                }
              }

              Widget field;
              if (qType == "checkbox") {
                List<String> opts = const <String>[];
                try {
                  final o = widget.ctrl.checkboxOptions(q);
                  if (o is List) opts = List<String>.from(o);
                } catch (_) {
                  if (q is Map && q["options"] is List) {
                    opts = List<String>.from(q["options"] as List);
                  }
                }

                Set<String> selected = <String>{};
                try {
                  final v = widget.ctrl.getCheckboxAnswer(widget.cardIndex, qIndex);
                  if (v is Set<String>) selected = v;
                  if (v is List) selected = v.cast<String>().toSet();
                } catch (_) {}
                if (selected.isEmpty) {
                  selected = AnswerStore.instance.getChecked(widget.cardIndex, qIndex);
                }

                field = _CheckboxList(
                  options: opts,
                  selectedValues: selected,
                  onToggle: (opt, on) {
                    bool updated = false;
                    try {
                      widget.ctrl.toggleCheckbox(widget.cardIndex, qIndex, opt, on);
                      updated = true;
                    } catch (_) {}
                    if (!updated) {
                      AnswerStore.instance.toggle(widget.cardIndex, qIndex, opt, on);
                    }
                    setState(() {});
                  },
                );
              } else {
                String initial = "";
                bool hasControllerVal = false;
                try {
                  final v = widget.ctrl.getTextAnswer(widget.cardIndex, qIndex);
                  if (v is String && v.isNotEmpty) {
                    initial = v;
                    hasControllerVal = true;
                  }
                } catch (_) {}
                if (!hasControllerVal) {
                  initial = AnswerStore.instance.getText(widget.cardIndex, qIndex);
                }

                final controller = TextEditingController(text: initial)
                  ..selection = TextSelection.collapsed(offset: initial.length);

                field = TextField(
                  controller: controller,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Type your answer…",
                    contentPadding: EdgeInsets.all(12),
                  ),
                  onChanged: (val) {
                    bool updated = false;
                    try {
                      widget.ctrl.setTextAnswer(widget.cardIndex, qIndex, val);
                      updated = true;
                    } catch (_) {}
                    if (!updated) {
                      AnswerStore.instance.setText(widget.cardIndex, qIndex, val);
                    }
                  },
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Q${qIndex + 1}: $qText",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    field,
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _MissingImageFallback extends StatelessWidget {
  const _MissingImageFallback({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      color: color,
      padding: const EdgeInsets.all(16),
      child: Text(
        "Image missing: $path",
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.humanIndex,
    required this.total,
    required this.onBack,
    required this.onForward,
  });

  final int humanIndex;
  final int total;
  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          label: const Text("Back"),
        ),
        Expanded(
          child: Center(
            child: Text(
              "Card $humanIndex of $total",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onForward,
          icon: const Icon(Icons.arrow_forward),
          label: const Text("Forward"),
        ),
      ],
    );
  }
}

class _CheckboxList extends StatelessWidget {
  const _CheckboxList({
    required this.options,
    required this.selectedValues,
    required this.onToggle,
  });

  final List<String> options;
  final Set<String> selectedValues;
  final void Function(String option, bool nowSelected) onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: -4,
      children: options.map((opt) {
        final isSelected = selectedValues.contains(opt);
        return FilterChip(
          label: Text(opt),
          selected: isSelected,
          onSelected: (val) => onToggle(opt, val),
        );
      }).toList(),
    );
  }
}

/// -------------------- EXPORT ACTIONS --------------------
/// HTML embeds images as base64 data URIs; filenames are timestamped and saved automatically.
Future<void> _exportHtml(BuildContext context, dynamic ctrl, int total) async {
  final messenger = ScaffoldMessenger.of(context);
  final models = await _gatherExportModels(ctrl, total, embedImages: true);
  if (models.isEmpty) {
    messenger.showSnackBar(const SnackBar(content: Text("No answered cards to export.")));
    return;
  }
  final dir = await _defaultExportDirectory();
  final path = "${dir.path}${Platform.pathSeparator}ifs_review_${_timestamp()}.html";
  final html = buildExportHtmlFrom(models);
  final bytes = utf8.encode(html);
  final f = File(path);
  await f.writeAsBytes(bytes, flush: true);
  messenger.showSnackBar(
    SnackBar(
      content: Text("Saved HTML: $path"),
      duration: const Duration(seconds: 8),
      action: SnackBarAction(
        label: "Copy Path",
        onPressed: () => Clipboard.setData(ClipboardData(text: path)),
      ),
    ),
  );
}

Future<void> _exportPdf(BuildContext context, dynamic ctrl, int total) async {
  final messenger = ScaffoldMessenger.of(context);
  final models = await _gatherExportModels(ctrl, total, embedImages: true);
  if (models.isEmpty) {
    messenger.showSnackBar(const SnackBar(content: Text("No answered cards to export.")));
    return;
  }
  final dir = await _defaultExportDirectory();
  final path = "${dir.path}${Platform.pathSeparator}ifs_review_${_timestamp()}.pdf";
  final pdfBytes = await buildExportPdfFrom(models);
  final f = File(path);
  await f.writeAsBytes(pdfBytes, flush: true);
  messenger.showSnackBar(
    SnackBar(
      content: Text("Saved PDF: $path"),
      duration: const Duration(seconds: 8),
      action: SnackBarAction(
        label: "Copy Path",
        onPressed: () => Clipboard.setData(ClipboardData(text: path)),
      ),
    ),
  );
}

/// Build models always using 7 shared questions when applicable.
/// Answers come from controller first, then AnswerStore.
Future<List<ExportCard>> _gatherExportModels(
  dynamic ctrl,
  int total, {
  required bool embedImages,
}) async {
  // Load questions.json once
  List<dynamic> all = const <dynamic>[];
  try {
    final raw = await rootBundle.loadString("assets/questions.json");
    final parsed = jsonDecode(raw);
    if (parsed is List) {
      all = parsed;
    } else if (parsed is Map && parsed["questions"] is List) {
      all = parsed["questions"] as List;
    }
  } catch (_) {}

  final bool sharedQuestions = all.length == 7; // same 7 for every card
  final List<dynamic> base7 = sharedQuestions
      ? all
      : (all.length >= 7 ? all.sublist(0, 7) : const <dynamic>[]);

  Future<(String? base64Img, String? path)> probeImage(int cardIndex) async {
    String? p;
    try {
      p = ctrl.imagePathForCurrentCard(cardIndex);
      if (p is! String || p.isEmpty) p = null;
    } catch (_) {}
    if (p == null) {
      final n = cardIndex + 1;
      final z2 = n.toString().padLeft(2, "0");
      final z3 = n.toString().padLeft(3, "0");
      final candidates = <String>[
        "assets/images/$n.png",
        "assets/images/$n.jpg",
        "assets/images/$z2.png",
        "assets/images/$z2.jpg",
        "assets/images/$z3.png",
        "assets/images/$z3.jpg",
        "assets/images/card_$n.png",
        "assets/images/card_$n.jpg",
        "assets/images/card_$z2.png",
        "assets/images/card_$z2.jpg",
        "assets/images/card_$z3.png",
        "assets/images/card_$z3.jpg",
      ];
      for (final c in candidates) {
        try { await rootBundle.load(c); p = c; break; } catch (_) {}
      }
    }
    if (p == null) return (null, null);
    if (!embedImages) return (null, p);
    try {
      final data = await rootBundle.load(p);
      final b64 = base64Encode(data.buffer.asUint8List());
      return (b64, null);
    } catch (_) {
      return (null, p);
    }
  }

  List<ExportCard> out = [];
  for (var i = 0; i < total; i++) {
    // Choose the questions for this card
    List<dynamic> qs;
    if (sharedQuestions) {
      qs = base7;
    } else if (all.length >= (i + 1) * 7) {
      final start = i * 7;
      qs = all.sublist(start, start + 7);
    } else {
      // fallback: at least provide the first 7 if present
      qs = base7;
    }

    // Collect answers for 7 questions (or however many we have)
    final qCount = qs.length;
    final answers = <dynamic>[];
    for (var q = 0; q < qCount; q++) {
      dynamic ans;
      try {
        final v = ctrl.getTextAnswer(i, q);
        if (v is String && v.isNotEmpty) ans = v;
      } catch (_) {}
      if (ans == null) {
        try {
          final v = ctrl.getCheckboxAnswer(i, q);
          if (v is Set<String>) ans = v.toList();
          if (v is List) ans = v.cast<String>();
        } catch (_) {}
      }
      if (ans == null) {
        final t = AnswerStore.instance.getText(i, q);
        if (t.isNotEmpty) {
          ans = t;
        } else {
          final s = AnswerStore.instance.getChecked(i, q);
          if (s.isNotEmpty) ans = s.toList();
        }
      }
      answers.add(ans);
    }

    // Keep only cards with at least one real answer
    final hasAny = answers.any((a) {
      if (a == null) return false;
      if (a is String) return a.trim().isNotEmpty;
      if (a is List) return a.isNotEmpty;
      return false;
    });
    if (!hasAny) continue;

    final (b64, imgPath) = await probeImage(i);

    out.add(ExportCard(
      base64Image: b64,
      imagePath: imgPath,
      questions: qs.map((q) => ExportQuestion(_qText(q))).toList(),
      answers: answers,
    ));
  }
  return out;
}

String _qText(dynamic q) {
  try {
    final t = q["text"];
    if (t is String) return t;
  } catch (_) {}
  try {
    final t = q.text; // ignore: avoid_dynamic_calls
    if (t is String) return t;
  } catch (_) {}
  return "Question";
}
