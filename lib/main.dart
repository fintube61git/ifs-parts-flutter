import "dart:convert";
import "dart:typed_data";

import "package:flutter/material.dart";
import "package:flutter/services.dart" show rootBundle;
import "package:package_info_plus/package_info_plus.dart";
import "package:pdf/pdf.dart";
import "package:pdf/widgets.dart" as pw;
import "package:printing/printing.dart"; // PdfGoogleFonts
import "package:provider/provider.dart";

import "controllers/card_controller.dart";
import "screens/card_screen.dart";

void main() {
  runApp(const MyApp());
}

/// Exposed so card_screen.dart can `show ThemeController` from main.dart.
class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  void toggle() {
    _mode = (_mode == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _version = "";

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _version = "v${info.version}+${info.buildNumber}";
      });
    } catch (_) {
      // ignore
    }
  }

  /// Count images under assets/images/ using the runtime AssetManifest.
  /// Includes: .png .jpg .jpeg .webp .gif; excludes names containing "icon".
  Future<int> _loadImageCount() async {
    try {
      final raw = await rootBundle.loadString("AssetManifest.json");
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final keys = decoded.keys.cast<String>();
        final imgs = keys.where((k) {
          if (!k.startsWith("assets/images/")) return false;
          final lower = k.toLowerCase();
          if (lower.contains("icon")) return false;
          return lower.endsWith(".png") ||
              lower.endsWith(".jpg") ||
              lower.endsWith(".jpeg") ||
              lower.endsWith(".webp") ||
              lower.endsWith(".gif");
        }).toList();
        return imgs.length;
      }
    } catch (_) {
      // fall through
    }
    // Fallback so the app still runs even if manifest parsing changes.
    return 75;
  }

  @override
  Widget build(BuildContext context) {
    // Provide ThemeController immediately so the shell renders correctly.
    return ChangeNotifierProvider(
      create: (_) => ThemeController(),
      child: Consumer<ThemeController>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: "IFS Parts Exploration",
            debugShowCheckedModeBanner: false,
            themeMode: theme.mode,
            theme: ThemeData.light(useMaterial3: true),
            darkTheme: ThemeData.dark(useMaterial3: true),
            home: FutureBuilder<int>(
              future: _loadImageCount(),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                final total = snap.data ?? 0;

                // CRITICAL: Provide CardController *above* CardScreen.
                return ChangeNotifierProvider<CardController>(
                  create: (_) => CardController(total: total),
                  child: Stack(
                    children: [
                      const CardScreen(), // no args; reads CardController via Provider
                      if (_version.isNotEmpty)
                        Positioned(
                          right: 10,
                          bottom: 8,
                          child: IgnorePointer(
                            child: Text(
                              _version,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// ---------- Export model used by CardScreen ----------
class ExportQuestion {
  final String text;
  ExportQuestion(this.text);
}

class ExportCard {
  final String? base64Image;
  final String? imagePath;
  final List<ExportQuestion> questions;
  /// answers[i] is either a String (text) or List<String> (checkboxes) or null
  final List<dynamic> answers;

  ExportCard({
    required this.base64Image,
    required this.imagePath,
    required this.questions,
    required this.answers,
  });
}

/// ---------- HTML export ----------
String buildExportHtmlFrom(List<ExportCard> cards) {
  final buf = StringBuffer();
  buf.writeln("<!doctype html>");
  buf.writeln("<html><head><meta charset='utf-8'>");
  buf.writeln("<title>IFS Review Export</title>");
  buf.writeln(
      "<style>body{font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif;margin:20px;} .card{display:grid;grid-template-columns:320px 1fr;gap:16px;page-break-after:always;margin-bottom:24px;} .img{border:1px solid #ddd;padding:8px;border-radius:8px;background:#fafafa} img{max-width:100%;height:auto} h2{margin:.2rem 0 .6rem 0;font-size:1.1rem} .qa{line-height:1.45} .q{font-weight:600;margin-top:.6rem} .a{margin-left:.6rem;white-space:pre-wrap} .muted{color:#666} .badge{display:inline-block;border:1px solid #bbb;padding:2px 6px;border-radius:999px;margin-right:6px;margin-bottom:4px;font-size:.9rem}</style>");
  buf.writeln("</head><body>");
  for (var i = 0; i < cards.length; i++) {
    final c = cards[i];
    buf.writeln("<section class='card'>");
    buf.write("<div class='img'>");
    final imgTag = _htmlImageTag(c);
    buf.write(imgTag);
    buf.writeln("</div>");
    buf.writeln("<div class='qa'>");
    buf.writeln("<h2>Card ${i + 1}</h2>");
    for (var q = 0; q < c.questions.length; q++) {
      final qText = _escapeHtml(c.questions[q].text);
      final ans = (q < c.answers.length) ? c.answers[q] : null;
      buf.writeln("<div class='q'>Q${q + 1}: $qText</div>");
      if (ans == null) {
        buf.writeln("<div class='a muted'>(no answer)</div>");
      } else if (ans is String) {
        buf.writeln("<div class='a'>${_escapeHtml(ans)}</div>");
      } else if (ans is List) {
        if (ans.isEmpty) {
          buf.writeln("<div class='a muted'>(no answer)</div>");
        } else {
          buf.write("<div class='a'>");
          for (final item in ans.cast<String>()) {
            buf.write("<span class='badge'>${_escapeHtml(item)}</span>");
          }
          buf.writeln("</div>");
        }
      } else {
        buf.writeln("<div class='a muted'>(no answer)</div>");
      }
    }
    buf.writeln("</div></section>");
  }
  buf.writeln("</body></html>");
  return buf.toString();
}

String _htmlImageTag(ExportCard c) {
  if (c.base64Image != null && c.base64Image!.isNotEmpty) {
    return "<img alt='card image' src='data:image/png;base64,${c.base64Image!}'>";
  }
  final p = c.imagePath;
  if (p == null || p.isEmpty) {
    return "<div class='muted'>[image missing]</div>";
  }
  return "<div class='muted'>[asset: ${_escapeHtml(p)} not embedded]</div>";
}

/// ---------- PDF export (zero decoration: no borders, no fills, no pills) ----------
Future<Uint8List> buildExportPdfFrom(List<ExportCard> cards) async {
  // Use Google fonts to guarantee Unicode without local TTF parsing
  final pw.Font regular = await PdfGoogleFonts.notoSansRegular();
  final pw.Font bold = await PdfGoogleFonts.notoSansBold();

  final theme = pw.ThemeData.withFont(base: regular, bold: bold);
  final doc = pw.Document(theme: theme);

  for (var i = 0; i < cards.length; i++) {
    final c = cards[i];

    // Image panel: no decoration at all; just constrain width.
    final imagePanel = pw.SizedBox(
      width: 180,
      child: _pdfImageWidget(c),
    );

    pw.Widget answersForList(List<String> items) {
      // Render as simple bullet text list to avoid any vector shapes.
      return pw.Wrap(
        spacing: 6,
        runSpacing: 2,
        children: items.map((s) => pw.Text("• $s", style: const pw.TextStyle(fontSize: 10))).toList(),
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              imagePanel,
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Card ${i + 1}",
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 8),
                    for (var q = 0; q < c.questions.length; q++)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 6),
                        child: _pdfQuestionAnswerPlain(c, q, answersForList),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  return doc.save();
}

pw.Widget _pdfImageWidget(ExportCard c) {
  if (c.base64Image != null && c.base64Image!.isNotEmpty) {
    try {
      final bytes = base64Decode(c.base64Image!);
      final img = pw.MemoryImage(bytes);
      return pw.Image(img, fit: pw.BoxFit.contain);
    } catch (_) {
      return pw.Text("[image decode failed]",
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey));
    }
  }
  if (c.imagePath != null && c.imagePath!.isNotEmpty) {
    return pw.Text("[asset not embedded: ${c.imagePath!}]",
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey));
  }
  return pw.Text("[image missing]",
      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey));
}

pw.Widget _pdfQuestionAnswerPlain(
  ExportCard c,
  int q,
  pw.Widget Function(List<String>) answersForList,
) {
  final qText = c.questions[q].text;
  final ans = (q < c.answers.length) ? c.answers[q] : null;

  final children = <pw.Widget>[
    pw.Text("Q${q + 1}: $qText", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
    pw.SizedBox(height: 2),
  ];

  if (ans == null) {
    children.add(pw.Text("(no answer)", style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey)));
  } else if (ans is String) {
    children.add(pw.Text(ans, style: const pw.TextStyle(fontSize: 11)));
  } else if (ans is List) {
    if (ans.isEmpty) {
      children.add(pw.Text("(no answer)", style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey)));
    } else {
      children.add(answersForList(ans.cast<String>()));
    }
  } else {
    children.add(pw.Text("(no answer)", style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey)));
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: children,
  );
}

String _escapeHtml(String input) {
  return input
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#39;");
}
