import "dart:convert";
import "dart:typed_data";

import "package:flutter/material.dart";
import "package:flutter/services.dart" show rootBundle;
import "package:package_info_plus/package_info_plus.dart";
import "package:pdf/pdf.dart";
import "package:pdf/widgets.dart" as pw;
import "package:printing/printing.dart" show PdfGoogleFonts;
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
  CardController? _cardController; // persist across theme toggles
  int? _total; // cached deck size

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _initDeckAndController();
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

  Future<void> _initDeckAndController() async {
    final total = await _loadImageCount();
    setState(() {
      _total = total;
      _cardController = CardController(total: total);
    });
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
    } catch (_) {}
    return 75; // fallback
  }

  @override
  Widget build(BuildContext context) {
    if (_cardController == null || _total == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController()),
        ChangeNotifierProvider<CardController>.value(value: _cardController!),
      ],
      child: Consumer<ThemeController>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: "IFS Parts Exploration",
            debugShowCheckedModeBanner: false,
            themeMode: theme.mode,
            theme: ThemeData.light(useMaterial3: true),
            darkTheme: ThemeData.dark(useMaterial3: true),
            home: Stack(
              children: [
                const CardScreen(),
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
      "<style>body{font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif;margin:20px;} .card{display:grid;grid-template-columns:320px 1fr;gap:16px;page-break-after:always;margin-bottom:24px;} .img{padding:8px;border-radius:8px;background:#fafafa} img{max-width:100%;height:auto} h2{margin:.2rem 0 .6rem 0;font-size:1.1rem} .qa{line-height:1.45} .q{font-weight:600;margin-top:.6rem} .a{margin-left:.6rem;white-space:pre-wrap} .muted{color:#666}</style>");
  buf.writeln("</head><body>");
  for (var i = 0; i < cards.length; i++) {
    final c = cards[i];
    buf.writeln("<section class='card'>");
    buf.write("<div class='img'>");
    buf.write(_htmlImageTag(c));
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
          final items = ans.cast<String>().map(_escapeHtml).toList();
          buf.writeln("<div class='a'>• ${items.join("   • ")}</div>");
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

/// ---------- PDF export (borderless, no shapes; Google fonts) ----------
Future<Uint8List> buildExportPdfFrom(List<ExportCard> cards) async {
  // Google-hosted Unicode fonts (avoids Helvetica warnings and local TTFs)
  final base = await PdfGoogleFonts.notoSansRegular();
  final bold = await PdfGoogleFonts.notoSansBold();

  final doc = pw.Document();

  for (var i = 0; i < cards.length; i++) {
    final c = cards[i];

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 24),
        build: (context) {
          return pw.Theme(
            data: pw.ThemeData.withFont(base: base, bold: bold),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Image column: NO border, NO background, NO decoration
                pw.Container(
                  width: 180,
                  padding: const pw.EdgeInsets.all(6),
                  child: _pdfImageWidget(c),
                ),
                pw.SizedBox(width: 12),
                // Text column: plain text only (no chip borders)
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
                          child: _pdfQuestionAnswer(c, q),
                        ),
                    ],
                  ),
                ),
              ],
            ),
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

pw.Widget _pdfQuestionAnswer(ExportCard c, int q) {
  final qText = c.questions[q].text;
  final ans = (q < c.answers.length) ? c.answers[q] : null;

  final widgets = <pw.Widget>[
    pw.Text(
      "Q${q + 1}: $qText",
      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 2),
  ];

  if (ans == null) {
    widgets.add(pw.Text("(no answer)",
        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey)));
  } else if (ans is String) {
    widgets.add(pw.Text(ans, style: const pw.TextStyle(fontSize: 11)));
  } else if (ans is List) {
    if (ans.isEmpty) {
      widgets.add(pw.Text("(no answer)",
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey)));
    } else {
      final items = ans.cast<String>();
      final bullet = "• ${items.join("   • ")}";
      widgets.add(pw.Text(bullet, style: const pw.TextStyle(fontSize: 11)));
    }
  } else {
    widgets.add(pw.Text("(no answer)",
        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey)));
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: widgets,
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
