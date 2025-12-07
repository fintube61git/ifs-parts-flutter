/// Models used for exporting cards (HTML and PDF).

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
