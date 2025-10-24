import "dart:convert";
import "dart:typed_data";

import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:pdf/widgets.dart" as pw;
import "package:pdf/pdf.dart" as pdf; // for PdfColor

import "controllers/card_controller.dart";
import "controllers/theme_controller.dart";
import "controllers/ui_heartbeat.dart";
import "screens/card_screen.dart";
import "screens/landing_page.dart"; // ← ADDED: import for new Landing Page

void main() {
  runApp(const IfsApp());
}


class IfsApp extends StatelessWidget {
  const IfsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Use 99 cards with full shuffling on every launch
        ChangeNotifierProvider<CardController>(create: (_) => CardController(total: 99)),
        ChangeNotifierProvider<UiHeartbeat>(create: (_) => UiHeartbeat()),
        ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController()),
      ],
      child: Consumer<ThemeController>(
        builder: (_, theme, __) => MaterialApp(
          title: "IFS Parts Exploration",
          themeMode: theme.mode,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.dark,
          ),
          home: const LandingPage(), // ← CHANGED: now uses LandingPage
        ),
      ),
    );
  }
}

/// =====================================================
/// EXPORT HELPERS (HTML + PDF) – compile-safe, easy to wire
/// Models used by CardScreen export actions.
/// =====================================================

class ExportCard {
  final String? base64Image;      // optional inline image
  final String? imagePath;        // fallback text if missing image
  final List<ExportQuestion> questions;
  final List<dynamic> answers;    // String or List<String> (for checkbox)

  const ExportCard({
    required this.base64Image,
    required this.imagePath,
    required this.questions,
    required this.answers,
  });
}

class ExportQuestion {
  final String text;
  const ExportQuestion(this.text);
}

/// ---- HTML ----
String buildExportHtmlFrom(List<ExportCard> models) {
  final buffer = StringBuffer();
  buffer.writeln("<!DOCTYPE html>");
  buffer.writeln('<html lang="en"><head><meta charset="utf-8">');
  buffer.writeln('<meta name="viewport" content="width=device-width, initial-scale=1">');
  buffer.writeln("<title>IFS Parts – Export</title>");
  buffer.writeln("<style>");
  buffer.writeln("  body { font-family: Arial, sans-serif; margin: 16px; }");
  buffer.writeln("  .card { display: grid; grid-template-columns: 1fr 1.2fr; gap: 16px; page-break-after: always; }");
  buffer.writeln("  .imgwrap { border: 1px solid #ccc; padding: 8px; }");
  buffer.writeln("  .qa { }");
  buffer.writeln("  .q { font-weight: bold; margin-top: 8px; }");
  buffer.writeln("  .a { white-space: pre-wrap; }");
  buffer.writeln("</style></head><body>");

  for (final cm in models) {
    final imgHtml = _imageHtml(cm.base64Image, cm.imagePath);
    buffer.writeln('<section class="card">');
    buffer.writeln('<div class="imgwrap">$imgHtml</div>');
    buffer.writeln('<div class="qa">');

    for (var i = 0; i < cm.questions.length; i++) {
      final q = cm.questions[i];
      final qText = _escapeHtml(q.text);
      final aHtml = _answerHtml(i < cm.answers.length ? cm.answers[i] : null);
      buffer.writeln('<div class="q">Q${i + 1}: $qText</div>');
      buffer.writeln('<div class="a">$aHtml</div>');
    }

    buffer.writeln("</div></section>");
  }

  buffer.writeln("</body></html>");
  return buffer.toString();
}

/// ---- PDF ----
Future<Uint8List> buildExportPdfFrom(List<ExportCard> models) async {
  final doc = pw.Document();

  for (final cm in models) {
    final imageProvider = (cm.base64Image != null && cm.base64Image!.isNotEmpty)
        ? pw.MemoryImage(base64Decode(cm.base64Image!))
        : null;

    doc.addPage(
      pw.Page(
        build: (ctx) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Image (left)
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: pdf.PdfColor(0.8, 0.8, 0.8)),
                    ),
                    child: imageProvider != null
                        ? pw.Image(imageProvider, fit: pw.BoxFit.contain)
                        : pw.Text("Image missing: ${cm.imagePath ?? "unknown"}"),
                  ),
                ),
                pw.SizedBox(width: 16),
                // QA (right)
                pw.Expanded(
                  flex: 7,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: List.generate(cm.questions.length, (i) {
                      final q = cm.questions[i];
                      final ans = i < cm.answers.length ? cm.answers[i] : null;
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              "Q${i + 1}: ${q.text}",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 4),
                            _pdfAnswerWidget(ans),
                          ],
                        ),
                      );
                    }),
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

/// ---- shared helpers ----
String _imageHtml(String? base64, String? path) {
  if (base64 != null && base64.isNotEmpty) {
    return '<img alt="card image" style="max-width:100%;height:auto" src="data:image/png;base64,$base64" />';
  }
  final safe = _escapeHtml(path ?? "unknown");
  return "<div>Image missing: $safe</div>";
}

String _answerHtml(dynamic ans) {
  if (ans == null) return "<em>(no answer)</em>";
  if (ans is String) return _escapeHtml(ans);
  if (ans is List) {
    final parts = ans.map((e) => _escapeHtml("$e")).toList();
    return parts.isEmpty ? "<em>(no selections)</em>" : parts.map((p) => "• $p").join("<br>");
  }
  return _escapeHtml("$ans");
}

/// Escape minimal HTML chars safely.
String _escapeHtml(String s) {
  return s
      .replaceAll("&", "&amp;")
      .replaceAll("<", "<")
      .replaceAll(">", ">")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#39;");
}

pw.Widget _pdfAnswerWidget(dynamic ans) {
  if (ans == null) {
    return pw.Text("(no answer)", style: pw.TextStyle(fontStyle: pw.FontStyle.italic));
  }
  if (ans is String) return pw.Text(ans);
  if (ans is List) return pw.Text(ans.map((e) => "• $e").join("\n"));
  return pw.Text("$ans");
}