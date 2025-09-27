// Welcome to Release 1.0 of your application.
// This is a complete, runnable Flutter app.
// I have added comments to explain what each part does.

import 'package:flutter/material.dart';

void main() {
  // The main() function is the entry point for your application.
  // It tells Flutter to run the MyApp widget.
  runApp(const MyApp());
}

// MyApp is the root widget of your application.
// It sets up the basic app structure, like the title and theme.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parts Explorer',
      // We'll add the dark/light theme toggle in a future release.
      // For now, it starts in light mode.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // The home property defines what the user sees first.
      // We are pointing it to our MainScreen widget.
      home: const MainScreen(),
    );
  }
}

// MainScreen is where the primary UI of your app lives.
// It's a "StatefulWidget" because it will need to manage changing data,
// like which card is currently being viewed.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // In future releases, this will be a list of your actual cards.
  // For now, it's just a number to keep track of the current card.
  int _currentCardIndex = 0;

  void _nextCard() {
    // This function will eventually move to the next card.
    // We will add the logic in the next release.
    setState(() {
      // For now, we just pretend we have 5 cards.
      if (_currentCardIndex < 4) {
        _currentCardIndex++;
      }
    });
  }

  void _previousCard() {
    // This function will eventually move to the previous card.
    setState(() {
      if (_currentCardIndex > 0) {
        _currentCardIndex--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold provides the standard app layout structure (app bar, body, etc.).
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // The title bar at the top of the application.
        title: const Text('Parts Explorer - Release 1.0'),
      ),
      // The body is where the main content goes.
      body: Row(
        // The Row widget arranges its children horizontally.
        children: [
          // Expanded tells its child to take up all available space.
          // This creates our two-pane layout.

          // --- LEFT PANE: IMAGE ---
          Expanded(
            flex: 2, // Give the left pane 2/3 of the space
            child: Container(
              color: Colors.grey[200],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.image, size: 100, color: Colors.grey),
                    const SizedBox(height: 20),
                    Text(
                      'Image for Card #${_currentCardIndex + 1} Goes Here',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // A thin vertical line to separate the panes.
          const VerticalDivider(width: 1),

          // --- RIGHT PANE: QUESTIONS ---
          Expanded(
            flex: 1, // Give the right pane 1/3 of the space
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.question_answer, size: 100, color: Colors.grey),
                    const SizedBox(height: 20),
                    Text(
                      'Questions for Card #${_currentCardIndex + 1} Go Here',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // The bottom navigation bar holds our control buttons.
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton.icon(
              onPressed: _previousCard,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
            ),
            // This Text widget shows the current card number.
            Text(
              'Card ${_currentCardIndex + 1} / 5',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ElevatedButton.icon(
              onPressed: _nextCard,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
