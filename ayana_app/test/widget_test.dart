import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ayana_app/screens/onboarding_screen.dart';
import 'package:ayana_app/screens/welcome_auth_screen.dart';

void main() {
  testWidgets('Onboarding navigue vers Welcome après « Passer »',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    expect(find.text('Bienvenue sur AYANA'), findsOneWidget);
    expect(find.text('Passer →'), findsOneWidget);

    await tester.tap(find.text('Passer →'));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeAuthScreen), findsOneWidget);
    expect(find.textContaining('Créer mon compte'), findsOneWidget);
  });
}