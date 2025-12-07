import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ifs_parts_flutter/main.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const IfsApp());

    // Verify that the app builds without errors.
    // The landing page should be displayed initially.
    await tester.pumpAndSettle();

    // Basic smoke test - just verify the app loads
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
