import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

import 'controllers/card_controller.dart';
import 'controllers/ui_heartbeat.dart';
import 'screens/card_screen.dart';
import 'services/data_service.dart';

// PDF export
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IfsPartsApp());
}

class IfsPartsApp extends StatelessWidget {
  const IfsPartsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IFS Parts Exploration',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4C6EF5),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const _Bootstrap(),
    );
  }
}

/// Bootstraps DataService and then builds the full app
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  final DataService _data = DataService();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _data.load();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_data.total == 0) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No cards found in assets/images/. Check pubspec.yaml and asset paths.',
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DataService>.value(value: _data),
        ChangeNotifierProvider(
          create: (_) => CardController(total: _data.total),
        ),
        ChangeNotifierProvider(
          create: (_) => UiHeartbeat(),
        ),
      ],
      child: CardScreen(
        // LEFT pane — image
        cardPaneBuilder: (ctx, index) {
          final data = ctx.watch<DataService>();
          final card = data.cards[index];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 3 / 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(ctx).dividerColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      card.imageAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, st) => Center(
                        child: Text(
                          'Missing image:\n${card.imageAsset}',
                          textAlign: TextAlign.center,
                          style: Theme.of(ctx).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },

        // RIGHT pane — questions (text + checkbox types)
        questionsPaneBuilder: (ctx, index) {
          final data = ctx.watch<DataService>();
          final card = data.cards[index];
          final qs = card.questions;

          if (qs.isEmpty) {
            return Text(
              'No questions for Card ${index + 1}',
              style: Theme.of(ctx).textTheme.bodyLarge,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Questions for Card ${index + 1}',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),

              for (var i = 0; i < qs.length; i++) ...[
                _QuestionWidget(
                  cardIndex: index,
                  q: qs[i],
                  displayNumber: i + 1,
                ),
                const SizedBox(height: 16),
              ],
            ],
          );
        },

        // Cards with =1 non-empty answer
        getAnsweredCardIndices: () {
          return _AnswersStore.instance.answeredIndices();
        },

        // Export answered cards only — HTML and PDF
        onExport: (answeredIndices, format) async {
          if (format == ExportFormat.html) {
            final suggestedName =
                'ifs_parts_export_${DateTime.now().toIso8601String().replaceAll(':', '-')}.html';

            final saveLoc = await getSaveLocation(
              acceptedTypeGroups: [
                const XTypeGroup(label: 'HTML', extensions: ['html', 'htm']),
              ],
              suggestedName: suggestedName,
            );
            if (saveLoc == null) return;

            final html = await _buildHtmlTwoColumn(
              answeredIndices: answeredIndices,
              data: _data,
              answers: _AnswersStore.instance,
            );
            final file = File(saveLoc.path);
            await file.writeAsString(html);
            return;
          }

          // PDF export — two columns with page break per card
          final suggestedName =
              'ifs_parts_export_${DateTime.now().toIso8601String().replaceAll(':', '-')}.pdf';

          final saveLoc = await getSaveLocation(
            acceptedTypeGroups: [
              const XTypeGroup(label: 'PDF', extensions: ['pdf']),
            ],
            suggestedName: suggestedName,
          );
          if (saveLoc == null) return;

          final pdfBytes = await _buildPdfTwoColumn(
            answeredIndices: answeredIndices,
            data: _data,
            answers: _AnswersStore.instance,
          );
          final file = File(saveLoc.path);
          await file.writeAsBytes(pdfBytes);
        },
      ),
    );
  }

  // ---------- HTML (two-column per card, embedded base64 image from assets) ----------

  Future<String> _buildHtmlTwoColumn({
    required List<int> answeredIndices,
    required DataService data,
    required _AnswersStore answers,
  }) async {
    final buf = StringBuffer();
    buf.writeln('<!doctype html>');
    buf.writeln('<html><head><meta charset="utf-8">');
    buf.writeln('<title>IFS Parts Exploration - Export</title>');
    buf.writeln('<style>'
        'body{font-family:system-ui,-apple-system,Segoe UI,Roboto,Ubuntu;line-height:1.45;margin:24px;}'
        'h1{margin:0 0 16px 0;font-size:20px;}'
        '.meta{color:#555;margin-bottom:16px;}'
        '.card{break-inside:avoid;border-top:1px solid #ddd;padding-top:16px;margin-top:16px;}'
        '.grid{display:grid;grid-template-columns:1fr 1fr;gap:16px;align-items:start;}'
        '.imgbox{border:1px solid #ddd;border-radius:12px;padding:8px;display:flex;justify-content:center;align-items:center;aspect-ratio:3/4;overflow:hidden;}'
        '.imgbox img{max-width:100%;max-height:100%;object-fit:contain;}'
        '.qa .qid{font-weight:600;margin-top:8px;}'
        '.ans{white-space:pre-wrap;border:1px solid #ddd;border-radius:8px;padding:8px;margin-top:4px;}'
        '.chips{display:flex;flex-wrap:wrap;gap:6px;margin-top:6px;}'
        '.chip{border:1px solid #999;border-radius:999px;padding:2px 8px;font-size:12px;}'
        '@media print {.card{page-break-inside:avoid;}}'
        '</style>');
    buf.writeln('</head><body>');
    buf.writeln('<h1>IFS Parts Exploration - Export</h1>');
    buf.writeln('<div class="meta">Generated: ${DateTime.now().toIso8601String()}</div>');

    for (final idx in answeredIndices) {
      final card = data.cards[idx];
      final cardAnswers = answers.getCardAnswers(idx);
      if (cardAnswers.isEmpty) continue;

      final imgB64 = await _tryAssetAsBase64(card.imageAsset);

      buf.writeln('<div class="card">');
      buf.writeln('<div class="grid">');

      // Left: image
      buf.writeln('<div class="imgbox">');
      if (imgB64 != null) {
        final mime = _guessMime(card.imageAsset);
        buf.writeln('<img alt="Card ${idx + 1}" src="data:$mime;base64,$imgB64">');
      } else {
        buf.writeln('<div>Missing image: ${_escapeHtml(card.imageAsset)}</div>');
      }
      buf.writeln('</div>');

      // Right: questions/answers
      buf.writeln('<div class="qa">');
      buf.writeln('<div><strong>Card ${idx + 1}</strong> — ${_escapeHtml(card.imageAsset)}</div>');
      for (final q in card.questions) {
        if (!cardAnswers.containsKey(q.id)) continue;

        buf.writeln('<div class="qid">${_escapeHtml(q.id)}: ${_escapeHtml(q.text)}</div>');
        final ans = cardAnswers[q.id];
        if (q.type == 'checkbox') {
          final list = (ans is List) ? ans.whereType<String>().toList() : <String>[];
          buf.writeln('<div class="chips">');
          for (final v in list) {
            buf.writeln('<span class="chip">${_escapeHtml(v)}</span>');
          }
          buf.writeln('</div>');
        } else {
          buf.writeln('<div class="ans">${_escapeHtml(ans.toString())}</div>');
        }
      }
      buf.writeln('</div>'); // qa

      buf.writeln('</div>'); // grid
      buf.writeln('</div>'); // card
    }

    buf.writeln('</body></html>');
    return buf.toString();
  }

  Future<String?> _tryAssetAsBase64(String assetPath) async {
    try {
      final bd = await rootBundle.load(assetPath);
      return base64Encode(bd.buffer.asUint8List());
    } catch (_) {
      // Fallback to disk if running outside bundled assets
      try {
        final bytes = await File(assetPath).readAsBytes();
        return base64Encode(bytes);
      } catch (_) {
        return null;
      }
    }
  }

  String _guessMime(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.jpg') || p.endsWith('.jpeg')) return 'image/jpeg';
    if (p.endsWith('.webp')) return 'image/webp';
    return 'application/octet-stream';
  }

  String _escapeHtml(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  // ---------- PDF (two-column per card, page break per card; image from assets) ----------

  Future<List<int>> _buildPdfTwoColumn({
    required List<int> answeredIndices,
    required DataService data,
    required _AnswersStore answers,
  }) async {
    final doc = pw.Document();

    final theme = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );

    for (var idxI = 0; idxI < answeredIndices.length; idxI++) {
      final idx = answeredIndices[idxI];
      final card = data.cards[idx];
      final cardAnswers = answers.getCardAnswers(idx);
      if (cardAnswers.isEmpty) continue;

      // Load image bytes from assets (with fallback to disk)
      pw.MemoryImage? img;
      final bytes = await _tryAssetBytes(card.imageAsset);
      if (bytes != null) {
        img = pw.MemoryImage(bytes);
      }

      doc.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(margin: const pw.EdgeInsets.all(24), theme: theme),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('IFS Parts Exploration - Export',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text('Generated: ${DateTime.now().toIso8601String()}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                pw.SizedBox(height: 12),
                pw.Text('Card ${idx + 1} - ${card.imageAsset}',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // LEFT: image (boxed, approx 3:4 area)
                    pw.Expanded(
                      flex: 3,
                      child: pw.Container(
                        height: 380,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey400),
                          borderRadius: pw.BorderRadius.circular(12),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                        child: img != null
                            ? pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain))
                            : pw.Center(
                                child: pw.Text('Missing image: ${card.imageAsset}',
                                    style: const pw.TextStyle(fontSize: 10)),
                              ),
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    // RIGHT: Q/A
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          for (final q in card.questions)
                            if (cardAnswers.containsKey(q.id)) ...[
                              pw.Text('${q.id}: ${q.text}',
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 4),
                              if (q.type == 'checkbox') ...[
                                pw.Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final v in ((cardAnswers[q.id] ?? []) as List).whereType<String>())
                                      pw.Container(
                                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: pw.BoxDecoration(
                                          border: pw.Border.all(color: PdfColors.grey700),
                                          borderRadius: pw.BorderRadius.circular(999),
                                        ),
                                        child: pw.Text(v, style: const pw.TextStyle(fontSize: 10)),
                                      ),
                                  ],
                                ),
                              ] else ...[
                                pw.Container(
                                  width: double.infinity,
                                  padding: const pw.EdgeInsets.all(8),
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(color: PdfColors.grey600),
                                    borderRadius: pw.BorderRadius.circular(8),
                                  ),
                                  child: pw.Text(cardAnswers[q.id].toString()),
                                ),
                              ],
                              pw.SizedBox(height: 10),
                            ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ); // one card per page
    }

    return doc.save();
  }

  Future<Uint8List?> _tryAssetBytes(String assetPath) async {
    try {
      final bd = await rootBundle.load(assetPath);
      return bd.buffer.asUint8List();
    } catch (_) {
      try {
        final f = File(assetPath);
        if (await f.exists()) {
          return await f.readAsBytes();
        }
      } catch (_) {}
    }
    return null;
  }
}

/// Renders either a TextFormField (type=text) or a list of checkboxes (type=checkbox)
class _QuestionWidget extends StatefulWidget {
  final int cardIndex;
  final Question q;
  final int displayNumber;

  const _QuestionWidget({
    required this.cardIndex,
    required this.q,
    required this.displayNumber,
  });

  @override
  State<_QuestionWidget> createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<_QuestionWidget> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    if (widget.q.type == 'text') {
      _ctrl = TextEditingController(
        text: _AnswersStore.instance.getText(widget.cardIndex, widget.q.id),
      );
    } else {
      _ctrl = TextEditingController(); // unused for checkbox
    }
  }

  @override
  void didUpdateWidget(covariant _QuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.q.type == 'text') {
      _ctrl.text =
          _AnswersStore.instance.getText(widget.cardIndex, widget.q.id);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heartbeat = context.read<UiHeartbeat>();
    final label = widget.q.id.startsWith('Q')
        ? 'Q${widget.displayNumber}: ${widget.q.text}'
        : widget.q.text;

    if (widget.q.type == 'checkbox') {
      final selected =
          _AnswersStore.instance.getMulti(widget.cardIndex, widget.q.id);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final opt in widget.q.options)
                FilterChip(
                  key: ValueKey('chk-${widget.cardIndex}-${widget.q.id}-$opt'),
                  label: Text(opt),
                  selected: selected.contains(opt),
                  onSelected: (val) {
                    setState(() {
                      _AnswersStore.instance
                          .toggleMulti(widget.cardIndex, widget.q.id, opt, val);
                    });
                    heartbeat.ping(); // rebuild CardScreen/AppBar/status/export
                  },
                ),
            ],
          ),
        ],
      );
    }

    // Text question
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 6),
        TextFormField(autofocus: (widget.displayNumber == 1 && widget.q.type == 'text'), 
          key: ValueKey('txt-${widget.cardIndex}-${widget.q.id}'),
          controller: _ctrl,
          minLines: 2,
          maxLines: null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Type your answer…',
          ),
          onChanged: (val) {
            _AnswersStore.instance.setText(
                widget.cardIndex, widget.q.id, val);
            setState(() {});   // keep field in sync
            heartbeat.ping();  // rebuild CardScreen/AppBar/status/export
          },
        ),
      ],
    );
  }
}

/// Answers store: per-card, per-question.id.
/// For text ? String; for checkbox ? Set<String>.
class _AnswersStore {
  _AnswersStore._();
  static final _AnswersStore instance = _AnswersStore._();

  final Map<int, Map<String, dynamic>> _store = {};

  String getText(int cardIndex, String qid) {
    final v = _store[cardIndex]?[qid];
    return v is String ? v : '';
  }

  void setText(int cardIndex, String qid, String value) {
    final m = _store.putIfAbsent(cardIndex, () => <String, dynamic>{});
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      m.remove(qid);
      if (m.isEmpty) _store.remove(cardIndex);
    } else {
      m[qid] = trimmed;
    }
  }

  Set<String> getMulti(int cardIndex, String qid) {
    final v = _store[cardIndex]?[qid];
    if (v is Set<String>) return v;
    if (v is List) return v.whereType<String>().toSet();
    return <String>{};
  }

  void toggleMulti(int cardIndex, String qid, String option, bool enabled) {
    final m = _store.putIfAbsent(cardIndex, () => <String, dynamic>{});
    final set = (m[qid] is Set<String>)
        ? (m[qid] as Set<String>)
        : (m[qid] is List)
            ? (m[qid] as List).whereType<String>().toSet()
            : <String>{};
    if (enabled) {
      set.add(option);
    } else {
      set.remove(option);
    }
    if (set.isEmpty) {
      m.remove(qid);
      if (m.isEmpty) _store.remove(cardIndex);
    } else {
      m[qid] = set;
    }
  }

  List<int> answeredIndices() {
    final out = <int>[];
    for (final entry in _store.entries) {
      final hasAnswer = entry.value.values.any((v) {
        if (v is String) return v.trim().isNotEmpty;
        if (v is Set) return v.isNotEmpty;
        if (v is List) return v.isNotEmpty;
        return false;
      });
      if (hasAnswer) out.add(entry.key);
    }
    out.sort();
    return out;
  }

  Map<String, dynamic> getCardAnswers(int cardIndex) {
    final src = _store[cardIndex];
    if (src == null) return {};
    final out = <String, dynamic>{};
    for (final e in src.entries) {
      final v = e.value;
      if (v is Set<String>) {
        out[e.key] = v.toList()..sort();
      } else {
        out[e.key] = v;
      }
    }
    return out;
  }
}
