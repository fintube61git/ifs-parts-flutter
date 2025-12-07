/// Application-wide constants.
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // Card configuration
  static const int totalCards = 99;
  static const int defaultCardIndex = 0;

  // Layout breakpoints for responsive design
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;
  static const double wideDesktopBreakpoint = 1600.0;

  // Landing page responsive breakpoint
  static const double landingWideBreakpoint = 700.0;

  // Image configuration
  static const String imageAssetPath = 'assets/images/';
  static const String landingImagePath = 'assets/landing_images/';
  static const List<String> supportedImageExtensions = ['.png', '.jpg', '.jpeg', '.webp'];

  // Question configuration
  static const String questionsAssetPath = 'assets/questions.json';
  static const String textQuestionType = 'text';
  static const String checkboxQuestionType = 'checkbox';

  // Export configuration
  static const String exportHtmlTitle = 'IFS Parts – Export';
  static const String exportTimestampFormat = 'yyyyMMdd_HHmmss';

  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  static const double defaultBorderRadius = 8.0;
  static const double landingBorderRadius = 16.0;

  // Grid configuration for landing page
  static const int landingGridRows = 3;
  static const int landingGridColumns = 3;
  static const int landingTotalImages = 9;

  // Animation durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
}
