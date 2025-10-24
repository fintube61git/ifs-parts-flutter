import "dart:convert";
import "dart:io";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:path_provider/path_provider.dart";
import "package:provider/provider.dart";

import "../controllers/card_controller.dart";
import "../controllers/ui_heartbeat.dart";
import "../controllers/theme_controller.dart"; // ← NEW
import "../services/answer_store.dart";
import "../main.dart" show ExportCard, ExportQuestion, buildExportHtmlFrom, buildExportPdfFrom; // ← ThemeController REMOVED from here

/// --------- Default export directory & helpers (Downloads -> Documents) ---------
Future<Directory> _defaultExportDirectory() async {
  try {
    // On macOS, Downloads is often restricted — use Documents instead
    if (Platform.isMacOS) {
      final docs = await getApplicationDocumentsDirectory();
      if (docs.existsSync()) return docs;
    }
    // On Windows/Linux, try Downloads first
    final downloads = await getDownloadsDirectory();
    if (downloads != null && downloads.existsSync()) return downloads;
  } catch (_) {}
  // Final fallback for all platforms
  try {
    final docs = await getApplicationDocumentsDirectory();
    return docs;
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

    // Total cards (always 99)
    final int total = 99;

    // REAL original card index (0-based, for assets/answers)
    final int originalCardIndex = ctrl.originalCardIndex;

    // HUMAN COUNTER (visible position → 1-based for "Card X of Y")
    final int humanIndex = ctrl.displayIndexOneBased;

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
        imagePath = ctrl.imagePathForCurrentCard(originalCardIndex);
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
        questions = List<dynamic>.from(ctrl.questionsForCard(originalCardIndex));
      } catch (_) {
        questions = const <dynamic>[];
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: "Help",
          icon: const Icon(Icons.help_outline),
          onPressed: () => _showHelpDialog(context),
        ),
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
                              cardIndex: originalCardIndex, // REAL original index drives asset lookup
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
                              cardIndex: originalCardIndex, // REAL original index for answers/questions
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

  final int cardIndex; // REAL original index, 0-based
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
  final int cardIndex; // REAL original index
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
      content: const Text("Saved HTML file"),
      duration: const Duration(seconds: 8),
      action: SnackBarAction(
        label: "Show",
        onPressed: () {
          // Reveal file in Finder (macOS) or Explorer (Windows)
          if (Platform.isMacOS) {
            try {
              Process.runSync('open', ['-R', path]);
            } catch (e) {
              // Fallback: open the folder
              Process.runSync('open', [dir.path]);
            }
          } else if (Platform.isWindows) {
            try {
              Process.runSync('explorer', ['/select,', path]);
            } catch (e) {
              Process.runSync('explorer', [dir.path]);
            }
          }
        },
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
      content: const Text("Saved PDF file"),
      duration: const Duration(seconds: 8),
      action: SnackBarAction(
        label: "Show",
        onPressed: () {
          // Reveal file in Finder (macOS) or Explorer (Windows)
          if (Platform.isMacOS) {
            try {
              Process.runSync('open', ['-R', path]);
            } catch (e) {
              // Fallback: open the folder
              Process.runSync('open', [dir.path]);
            }
          } else if (Platform.isWindows) {
            try {
              Process.runSync('explorer', ['/select,', path]);
            } catch (e) {
              Process.runSync('explorer', [dir.path]);
            }
          }
        },
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
  // Iterate over ORIGINAL card indices (0 to 98), not shuffled positions
  for (var originalIndex = 0; originalIndex < total; originalIndex++) {
    // Choose the questions for this card
    List<dynamic> qs;
    if (sharedQuestions) {
      qs = base7;
    } else if (all.length >= (originalIndex + 1) * 7) {
      final start = originalIndex * 7;
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
        final v = ctrl.getTextAnswer(originalIndex, q);
        if (v is String && v.isNotEmpty) ans = v;
      } catch (_) {}
      if (ans == null) {
        try {
          final v = ctrl.getCheckboxAnswer(originalIndex, q);
          if (v is Set<String>) ans = v.toList();
          if (v is List) ans = v.cast<String>();
        } catch (_) {}
      }
      if (ans == null) {
        final t = AnswerStore.instance.getText(originalIndex, q);
        if (t.isNotEmpty) {
          ans = t;
        } else {
          final s = AnswerStore.instance.getChecked(originalIndex, q);
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

    final (b64, imgPath) = await probeImage(originalIndex);

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

/// --------- Help dialog ---------
void _showHelpDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) {
      final textTheme = Theme.of(ctx).textTheme;
      return AlertDialog(
        title: const Text("Help"),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("What this app does", style: textTheme.titleMedium),
                const SizedBox(height: 4),
                const Text(
                  "Browse a deck of images. If you notice a reaction to any card, you can answer one or more questions about it. "
                  "After you navigate away from the card, your answers are saved for this session so you can export them to your device and refer to them later. "
                  "When you close the app, the next time you open it starts a new review session (prior answers are not available in the app).",
                ),
                const SizedBox(height: 16),
                Text("Navigation", style: textTheme.titleMedium),
                const SizedBox(height: 4),
                const Text(
                  "Back / Forward: use the on-screen buttons or the Left/Right Arrow keys.\n"
                  "Wrap-around: after the last card, you loop back to the first (and vice-versa).\n"
                  "Shuffle: cards are randomized each time you open the app.",
                ),
                const SizedBox(height: 16),
                Text("Counter", style: textTheme.titleMedium),
                const SizedBox(height: 4),
                const Text("“Card X of Y” shows your position in this session — not any file name or card identifier."),
                const SizedBox(height: 16),
                Text("Exporting", style: textTheme.titleMedium),
                const SizedBox(height: 4),
                const Text(
                  "Export your answered cards to HTML or PDF. Files are saved to your Downloads folder "
                  "(or Documents if Downloads isn’t available). Filenames look like ifs_review_YYYYMMDD_HHMMSS.*",
                ),
                const SizedBox(height: 16),
                Text("Theme", style: textTheme.titleMedium),
                const SizedBox(height: 4),
                const Text(
                  "Toggle between Light/Dark. Depending on your OS, the first time you press the toggle it may require a second press to change. "
                  "This will be improved in a future release.",
                ),
                const SizedBox(height: 16),
                Text("Privacy", style: textTheme.titleMedium),
                const SizedBox(height: 4),
                const Text(
                  "This app does not save your answers between sessions. If you export to a file, that file will be available to anyone with access to the device "
                  "or location where it is saved. If you plan to share the file and it contains sensitive information, consider using encryption while sending it.",
                ),
                const SizedBox(height: 16),
                Text("About", style: textTheme.titleMedium),
                const SizedBox(height: 4),
                const Text("Version is shown at the bottom-right (e.g., v1.3.0+1300)."),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Close"),
          ),
        ],
      );
    },
  );
}