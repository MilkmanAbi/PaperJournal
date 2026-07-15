// This was still the default Flutter counter-app template test - didn't
// match AmberJournal at all (it was tapping a '+' icon that doesn't
// exist here), so it'd fail as soon as you ran `flutter test`. Swapped
// it for a basic smoke test: log out first so it's not depending on
// whatever session file happens to be sitting on disk, then just check
// LoginPage actually shows up.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:PaperJournal-M4/main.dart';
import 'package:PaperJournal-M4/global.dart';

void main() {
  testWidgets('shows the login page when logged out', (WidgetTester tester) async {
    Global.logout(); // make sure we start from a clean, logged-out state

    await tester.pumpWidget(const MyApp());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
