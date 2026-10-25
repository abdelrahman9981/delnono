import 'package:delnono/features/welcome/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/screen_harness.dart';

void main() {
  testWidgets("Welcome shows the doctor's photo and the waiting room, no placeholder", (tester) async {
    final h = ScreenHarness(initial: '/', routes: [GoRoute(path: '/', builder: (_, _) => const WelcomeScreen())], overrides: const []);
    await h.pump(tester);
    expect(find.byKey(const Key('welcome-doctor-photo')), findsOneWidget);
    expect(find.textContaining('صورة د.'), findsNothing);
    await tester.scrollUntilVisible(find.byKey(const Key('welcome-waiting-room')), 120, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('مكان الانتظار في العيادة'), findsOneWidget);
  });
}
