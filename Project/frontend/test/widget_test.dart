// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('VisionQuest app loads successfully', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VisionQuestApp());

    // Verify app title is present
    expect(find.text('VisionQuest - Backend Integration'), findsOneWidget);

    // Verify connection test button is present
    expect(find.byType(ElevatedButton), findsOneWidget);

    // Wait for loading to complete
    await tester.pumpAndSettle();

    // Verify we either see connected or not connected message
    final connectedFinder = find.text('Backend verbunden!');
    final disconnectedFinder = find.text('Backend nicht erreichbar');

    expect(
      connectedFinder.tryEvaluate() ? connectedFinder : disconnectedFinder,
      findsOneWidget,
    );
  });
}
