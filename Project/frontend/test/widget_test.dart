// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('Login screen loads with inputs', (WidgetTester tester) async {
    await tester.pumpWidget(const VisionQuestApp());

    expect(find.widgetWithText(AppBar, 'Login'), findsOneWidget);
    expect(find.text('Willkommen zurueck'), findsOneWidget);
    expect(find.text('Noch kein Konto? Registrieren'), findsOneWidget);

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('E-Mail'), findsOneWidget);
    expect(find.text('Passwort'), findsOneWidget);
  });

  testWidgets('Register screen opens from login', (WidgetTester tester) async {
    await tester.pumpWidget(const VisionQuestApp());

    await tester.tap(find.text('Noch kein Konto? Registrieren'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Registrieren'), findsOneWidget);
    expect(find.text('Konto erstellen'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
  });

  testWidgets('Login shows validation errors when empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const VisionQuestApp());

    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();

    expect(find.text('Bitte E-Mail eingeben.'), findsOneWidget);
    expect(find.text('Bitte Passwort eingeben.'), findsOneWidget);
  });

  testWidgets('Login validates email format', (WidgetTester tester) async {
    await tester.pumpWidget(const VisionQuestApp());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-Mail'),
      'ungueltig',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Passwort'),
      '123456',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();

    expect(find.text('Bitte eine gueltige E-Mail eingeben.'), findsOneWidget);
  });

  testWidgets('Register shows validation errors when empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const VisionQuestApp());

    await tester.tap(find.text('Noch kein Konto? Registrieren'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Registrieren'));
    await tester.pump();

    expect(find.text('Bitte Benutzername eingeben.'), findsOneWidget);
    expect(find.text('Bitte E-Mail eingeben.'), findsOneWidget);
    expect(find.text('Bitte Passwort eingeben.'), findsOneWidget);
    expect(find.text('Bitte Passwort bestaetigen.'), findsOneWidget);
  });

  testWidgets('Register validates matching passwords', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const VisionQuestApp());

    await tester.tap(find.text('Noch kein Konto? Registrieren'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Benutzername'),
      'tester',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-Mail'),
      'test@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Passwort'),
      '123456',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Passwort bestaetigen'),
      '123',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Registrieren'));
    await tester.pump();

    expect(find.text('Passwoerter stimmen nicht ueberein.'), findsOneWidget);
  });

  testWidgets('Register can navigate back to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const VisionQuestApp());

    await tester.tap(find.text('Noch kein Konto? Registrieren'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bereits ein Konto? Zum Login'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Login'), findsOneWidget);
  });

  testWidgets('Register validates email format', (WidgetTester tester) async {
    await tester.pumpWidget(const VisionQuestApp());

    await tester.tap(find.text('Noch kein Konto? Registrieren'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Benutzername'),
      'testuser',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-Mail'),
      'invalid-email',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Passwort'),
      'password123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Passwort bestaetigen'),
      'password123',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Registrieren'));
    await tester.pump();

    expect(find.text('Bitte eine gueltige E-Mail eingeben.'), findsOneWidget);
  });

  testWidgets('Register validates password length', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const VisionQuestApp());

    await tester.tap(find.text('Noch kein Konto? Registrieren'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Benutzername'),
      'testuser',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-Mail'),
      'test@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Passwort'),
      '12345',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Passwort bestaetigen'),
      '12345',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Registrieren'));
    await tester.pump();

    expect(
      find.text('Passwort muss mindestens 6 Zeichen haben.'),
      findsOneWidget,
    );
  });

  testWidgets('Login validates password length', (WidgetTester tester) async {
    await tester.pumpWidget(const VisionQuestApp());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-Mail'),
      'test@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Passwort'),
      '12345',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();

    expect(
      find.text('Passwort muss mindestens 6 Zeichen haben.'),
      findsOneWidget,
    );
  });

  testWidgets('Home screen displays after login placeholder', (
    WidgetTester tester,
  ) async {
    // Note: This test just checks the UI structure since we can't easily
    // mock the auth service to actually navigate to Home.
    // For integration tests, you'd need to mock the HTTP calls.
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.widgetWithText(AppBar, 'VisionQuest'), findsOneWidget);
    expect(find.text('Login erfolgreich'), findsOneWidget);
    expect(find.text('Du bist jetzt eingeloggt.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Logout'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('Home screen logout button exists', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.widgetWithText(FilledButton, 'Logout'), findsOneWidget);

    // Tap the logout button
    await tester.tap(find.widgetWithText(FilledButton, 'Logout'));
    await tester.pump();

    // Should show loading state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
