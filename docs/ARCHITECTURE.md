# IFS Parts Flutter - Architecture Documentation

## Overview
IFS Parts is a Flutter application for Internal Family Systems (IFS) therapeutic work. The application provides an offline, private tool for exploring 99 therapeutic cards with questions and answers.

## Architecture Pattern
The application follows a layered architecture with clear separation of concerns:

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│    (Screens, Widgets, UI Logic)     │
├─────────────────────────────────────┤
│       State Management Layer        │
│  (Controllers using ChangeNotifier) │
├─────────────────────────────────────┤
│         Business Logic Layer        │
│      (Services, Export Logic)       │
├─────────────────────────────────────┤
│           Data Layer                │
│    (Models, Storage, Constants)     │
└─────────────────────────────────────┘
```

## Directory Structure

```
lib/
├── controllers/          # State management controllers
│   ├── card_controller.dart      # Card navigation and shuffling
│   ├── theme_controller.dart     # Theme switching (light/dark)
│   └── ui_heartbeat.dart         # UI refresh trigger
├── exports/              # Export functionality
│   └── export_service.dart       # HTML and PDF export logic
├── models/               # Data models
│   ├── card_data.dart            # Card with image and questions
│   ├── question.dart             # Question model
│   └── export_models.dart        # Export-specific models
├── screens/              # UI screens
│   ├── landing_page.dart         # Entry screen
│   ├── card_screen.dart          # Main card exploration
│   ├── ifs_overview_screen.dart  # IFS information
│   ├── what_are_parts_screen.dart
│   ├── what_is_self_screen.dart
│   └── app_info_screen.dart
├── services/             # Business logic services
│   ├── answer_store.dart         # Answer persistence
│   └── data_service.dart         # Data loading from assets
├── utils/                # Utilities and helpers
│   ├── constants.dart            # App-wide constants
│   ├── file_helper.dart          # File operations
│   └── responsive_helper.dart    # Responsive design utilities
├── widgets/              # Reusable widgets
│   └── top_nav_bar.dart
└── main.dart             # Application entry point
```

## Key Components

### Controllers
Controllers manage application state using the Provider pattern with `ChangeNotifier`:

- **CardController**: Manages card shuffling and navigation
  - Shuffles 99 cards on startup
  - Provides circular navigation (wraps at ends)
  - Tracks current position and original card indices

- **ThemeController**: Manages light/dark theme switching
  - Supports system, light, and dark modes
  - Persists through app lifecycle

- **UiHeartbeat**: Triggers UI rebuilds when answers change
  - Simple notification mechanism for answer updates

### Services
Services handle business logic and data operations:

- **DataService**: Loads card images and questions from assets
  - Supports flexible JSON question formats
  - Natural sorting of image files
  - Dynamic asset manifest parsing

- **AnswerStore**: Singleton for storing user answers
  - Supports text and checkbox answers
  - Tracks answered card count
  - In-memory storage (reset on app restart)

- **ExportService**: Generates HTML and PDF exports
  - Embeds images as base64 in exports
  - Includes all answered cards with questions
  - Clean, printable formatting

### Models
Immutable data models with value semantics:

- **Question**: Question text with type (text/checkbox)
- **CardData**: Image asset path with questions
- **ExportCard**: Export-specific data structure

### Utilities
Helper classes for common operations:

- **AppConstants**: Application-wide constants
  - Card counts, breakpoints, paths
  - Layout dimensions and animations

- **ResponsiveHelper**: Responsive design utilities
  - Screen size detection (mobile/tablet/desktop)
  - Adaptive padding and font scaling

- **FileHelper**: File operations
  - Cross-platform export directory selection
  - File reveal in system explorer
  - Timestamp generation

## State Management
The app uses Provider for state management:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider<CardController>(...),
    ChangeNotifierProvider<ThemeController>(...),
    ChangeNotifierProvider<UiHeartbeat>(...),
  ],
  child: MaterialApp(...)
)
```

Screens consume state using:
- `context.watch<T>()` - Rebuild on state changes
- `context.read<T>()` - Access without rebuilding

## Data Flow

### Card Navigation
1. User taps navigation button
2. CardController updates current index
3. CardController notifies listeners
4. CardScreen rebuilds with new card
5. Image and questions loaded from assets

### Answer Storage
1. User types answer or selects checkbox
2. Answer stored in AnswerStore by card/question index
3. UiHeartbeat.ping() called
4. Widgets watching UiHeartbeat rebuild
5. Answer count updates

### Export Flow
1. User selects export format (HTML/PDF)
2. ExportService gathers answered cards
3. Images embedded as base64
4. File written to export directory
5. System file explorer opened to show file

## Responsive Design
The app supports multiple screen sizes:

- **Mobile** (< 600px): Single column, compact UI
- **Tablet** (600-1200px): Two columns, medium padding
- **Desktop** (1200px+): Full layout, large padding

Responsive breakpoints defined in `AppConstants` and used via `ResponsiveHelper`.

## Testing Strategy
Comprehensive test coverage across layers:

- **Unit Tests**: Models, controllers, services
- **Widget Tests**: Screen rendering and interaction
- **Integration Tests**: End-to-end user flows

Test files mirror source structure under `test/` directory.

## Build and Run

### Development
```bash
flutter pub get
flutter run
```

### Testing
```bash
flutter test
```

### Build for Production
```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```

## Dependencies
Key dependencies:
- `provider`: State management
- `path_provider`: File system access
- `pdf`: PDF generation
- `printing`: PDF utilities
- `window_size`: Desktop window management
- `package_info_plus`: App metadata
- `url_launcher`: External links

## Security Considerations
- No network requests (fully offline)
- No telemetry or analytics
- No data collection
- Answers stored in memory only
- Exports saved to user-controlled directories

## Future Improvements
- Answer persistence across sessions
- Customizable question sets
- Enhanced mobile gestures
- Accessibility improvements
- Internationalization support
