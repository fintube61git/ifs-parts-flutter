import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "controllers/card_controller.dart";
import "controllers/theme_controller.dart";
import "controllers/ui_heartbeat.dart";
import "screens/card_screen.dart";
import "screens/landing_page.dart";
import "utils/constants.dart";

void main() {
  runApp(const IfsApp());
}


class IfsApp extends StatelessWidget {
  const IfsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Use total cards with full shuffling on every launch
        ChangeNotifierProvider<CardController>(create: (_) => CardController(total: AppConstants.totalCards)),
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
          home: const LandingPage(),
        ),
      ),
    );
  }
}

