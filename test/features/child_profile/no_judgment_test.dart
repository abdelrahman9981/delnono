// SC-003, FR-005, D-37: no screen of the child profile may state or suggest a medical judgment.
// Renders every 003 screen with seed-like data and scans all text; also scans every app string.

import 'dart:convert';
import 'dart:io';

import 'package:delnono/core/launch/external_links.dart';
import 'package:delnono/features/child_profile/presentation/follow_up_screen.dart';
import 'package:delnono/features/child_profile/presentation/my_child_screen.dart';
import 'package:delnono/features/child_profile/presentation/vaccines_screen.dart';
import 'package:delnono/features/child_profile/presentation/visits_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/screen_harness.dart';
import 'fakes.dart';

const forbidden = [
  'طبيعي',
  'طبيعى',
  'المعدل',
  'ممتاز',
  'كويس',
  'سليم',
  'متأخر في النمو',
  'نسبة مئوية',
  'بيرسنتايل',
  'percentile',
  'normal',
  'on track',
];

class _Links implements ExternalLinks {
  @override
  Future<bool> openWhatsApp(String e164) async => true;

  @override
  Future<bool> callNumber(String number) async => true;
}

List<String> judgmentsIn(Iterable<String> texts) => [
      for (final t in texts)
        for (final w in forbidden)
          if (t.toLowerCase().contains(w)) '"$w" in "$t"',
    ];

void main() {
  final screens = <String, (String, Widget Function(String id))>{
    'my child': ('/children', (_) => const MyChildScreen()),
    'vaccines': ('/children/c1/vaccines', (id) => VaccinesScreen(childId: id)),
    'visits': ('/children/c1/visits', (id) => VisitsScreen(childId: id)),
    'follow-up': ('/children/c2/follow-up', (id) => FollowUpScreen(childId: 'c2')),
  };

  for (final MapEntry(key: name, value: (path, build)) in screens.entries) {
    testWidgets('$name shows values only, no judgments', (tester) async {
      final h = ScreenHarness(
        initial: path,
        routes: [GoRoute(path: path, builder: (_, _) => build('c1'))],
        overrides: [
          ...profileOverrides(),
          externalLinksProvider.overrideWithValue(_Links()),
        ],
      );
      await h.pump(tester);
      final seen = <String>{};
      for (var i = 0; i < 8; i++) {
        seen.addAll(tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? t.textSpan?.toPlainText() ?? ''));
        final lists = find.byType(Scrollable);
        if (lists.evaluate().isEmpty) break;
        await tester.drag(lists.first, const Offset(0, -500), warnIfMissed: false);
        await tester.pumpAndSettle();
      }
      expect(seen, isNotEmpty);
      expect(judgmentsIn(seen), isEmpty);
    });
  }

  test('no app string contains a judgment word', () {
    final arb = jsonDecode(File('l10n/app_ar.arb').readAsStringSync()) as Map<String, dynamic>;
    final strings = arb.entries.where((e) => !e.key.startsWith('@')).map((e) => '${e.value}');
    expect(judgmentsIn(strings), isEmpty);
  });
}
