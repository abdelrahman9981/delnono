import 'package:delnono/features/child_profile/presentation/visits_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/screen_harness.dart';
import 'fakes.dart';

void main() {
  Future<ScreenHarness> open(WidgetTester tester, String initial) async {
    final h = ScreenHarness(
      initial: initial,
      routes: [
        GoRoute(path: '/children/:id/visits', builder: (_, s) => VisitsScreen(childId: s.pathParameters['id']!)),
      ],
      overrides: profileOverrides(),
    );
    await h.pump(tester);
    return h;
  }

  testWidgets('visits newest first, with what was recorded (FR-013)', (tester) async {
    await open(tester, '/children/c1/visits');
    final dates = tester
        .widgetList<Text>(find.textContaining(' · كشف'))
        .map((t) => t.data!)
        .toList();
    expect(dates.first, startsWith('١٥ سبتمبر ٢٠٢٦'));
    expect(find.descendant(of: find.byKey(const Key('visit-v3')), matching: find.textContaining('الوزن ١٢٫٩ كجم')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('visit-v1')), matching: find.textContaining('[تطعيم مؤقت ٣]')), findsOneWidget);
  });

  testWidgets('no prescription entry on visits: photos are Phase 2 (FR-015, D-39)', (tester) async {
    await open(tester, '/children/c1/visits');
    expect(find.textContaining('روشت'), findsNothing);
  });

  testWidgets('no visits yet', (tester) async {
    await open(tester, '/children/c2/visits');
    expect(find.text('لسه مفيش زيارات متسجلة.'), findsOneWidget);
  });
}
