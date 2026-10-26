import 'package:delnono/features/child_profile/data/measurements_repository.dart';
import 'package:delnono/features/child_profile/presentation/my_child_screen.dart';
import 'package:delnono/features/children/data/children_repository.dart';
import 'package:delnono/features/registration/data/guardian_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/screen_harness.dart';
import 'fakes.dart';

void main() {
  Future<ScreenHarness> open(
    WidgetTester tester, {
    MemorySelectedChildStore? store,
    Map<String, List<Measurement>> measurements = const {'c1': youssefMeasurements, 'c2': salmaMeasurements},
    List<Child> children = const [youssef, salma],
    bool offline = false,
    List<({bool active, String startsOn, String endsOn})> packages = const [],
  }) async {
    final h = ScreenHarness(
      initial: '/children',
      routes: [GoRoute(path: '/children', builder: (_, _) => const MyChildScreen())],
      overrides: profileOverrides(
        store: store,
        measurements: measurements,
        children: children,
        offline: offline,
        packages: packages,
      ),
    );
    await h.pump(tester);
    return h;
  }

  Finder inCard(String key, Finder f) => find.descendant(of: find.byKey(Key(key)), matching: f);

  testWidgets('switcher lists the children; the first is shown by default (FR-001)', (tester) async {
    await open(tester);
    expect(inCard('child-switcher', find.text('يوسف')), findsOneWidget);
    expect(inCard('child-switcher', find.text('سلمى')), findsOneWidget);
    expect(find.text('آخر قياسات يوسف'), findsOneWidget);
  });

  testWidgets('latest weight, length and head, each with its own date (FR-003)', (tester) async {
    await open(tester);
    expect(inCard('measure-weight', find.text('١٢٫٩')), findsOneWidget);
    expect(inCard('measure-weight', find.text('اتقاس ١٥ سبتمبر ٢٠٢٦')), findsOneWidget);
    expect(inCard('measure-length', find.text('٩١')), findsOneWidget);
    expect(inCard('measure-head', find.text('٤٨')), findsOneWidget);
    expect(inCard('measure-head', find.text('اتقاس ١٥ مارس ٢٠٢٦')), findsOneWidget);
    expect(find.text('اتحدثت ١٥ سبتمبر ٢٠٢٦'), findsOneWidget);
  });

  testWidgets('switching child changes every section and is remembered (FR-001)', (tester) async {
    final store = MemorySelectedChildStore();
    await open(tester, store: store);
    await tester.tap(find.byKey(const Key('child-chip-c2')));
    await tester.pumpAndSettle();
    expect(find.text('آخر قياسات سلمى'), findsOneWidget);
    expect(inCard('measure-weight', find.text('٧٫٣')), findsOneWidget);
    expect(store.saved, 'c2');
  });

  testWidgets('the remembered child is shown at start', (tester) async {
    await open(tester, store: MemorySelectedChildStore()..saved = 'c2');
    expect(find.text('آخر قياسات سلمى'), findsOneWidget);
  });

  testWidgets('growth chart switches between weight, length and head (FR-004)', (tester) async {
    await open(tester);
    final chart = find.byKey(const Key('growth-chart'));
    await scrollTo(tester, chart);
    expect(inCard('growth-chart', find.text('الوزن بالنسبة للعمر')), findsOneWidget);
    await tester.tap(inCard('growth-chart', find.text('الطول')));
    await tester.pumpAndSettle();
    expect(inCard('growth-chart', find.text('الطول بالنسبة للعمر')), findsOneWidget);
    await tester.tap(inCard('growth-chart', find.text('محيط الرأس')));
    await tester.pumpAndSettle();
    expect(inCard('growth-chart', find.text('محيط الرأس بالنسبة للعمر')), findsOneWidget);
  });

  testWidgets('no measurements: a note and no chart (US1 scenario 5)', (tester) async {
    await open(tester, measurements: const {});
    expect(find.byKey(const Key('no-measurements')), findsOneWidget);
    expect(find.byKey(const Key('growth-chart')), findsNothing);
  });

  testWidgets('entries open vaccines, visits, follow-up and the details screen', (tester) async {
    final h = await open(tester);
    for (final (key, path) in [
      ('entry-vaccines', '/children/c1/vaccines'),
      ('entry-visits', '/children/c1/visits'),
      ('entry-follow-up', '/children/c1/follow-up'),
      ('entry-details', '/children/c1'),
    ]) {
      await tapVisible(tester, find.byKey(Key(key)));
      expect(h.location, path);
      h.router.go('/children');
      await tester.pumpAndSettle();
    }
  });

  testWidgets('allergies are shown on the details entry (FR-002)', (tester) async {
    await open(tester);
    await scrollTo(tester, find.byKey(const Key('entry-details')));
    expect(find.text('حساسية: بنسلين'), findsOneWidget);
  });

  testWidgets('add child', (tester) async {
    final h = await open(tester);
    await tapVisible(tester, find.byKey(const Key('add-child')));
    expect(h.location, '/children/add');
  });

  group('package (FR-020)', () {
    testWidgets('an active package shows its end date and months left', (tester) async {
      await open(tester, packages: const [(active: true, startsOn: '2026-01-12', endsOn: '2027-01-12')]);
      final card = find.byKey(const Key('package-card'));
      expect(find.descendant(of: card, matching: find.text('نشطة لحد ١٢ يناير ٢٠٢٧')), findsOneWidget);
      expect(find.descendant(of: card, matching: find.text('متبقي شهرين')), findsOneWidget);
      expect(find.descendant(of: card, matching: find.text('نشطة')), findsOneWidget);
    });

    testWidgets('an ended package shows as ended', (tester) async {
      await open(tester, packages: const [(active: true, startsOn: '2025-01-01', endsOn: '2026-01-01')]);
      expect(find.text('خلصت في ١ يناير ٢٠٢٦'), findsOneWidget);
    });

    testWidgets('no package, no card', (tester) async {
      await open(tester);
      expect(find.byKey(const Key('package-card')), findsNothing);
    });
  });

  group('offline (FR-022)', () {
    testWidgets('the last loaded data shows with an offline note', (tester) async {
      await open(tester, offline: true);
      expect(find.byKey(const Key('offline-note')), findsOneWidget);
      expect(find.text('آخر قياسات يوسف'), findsOneWidget);
    });

    testWidgets('no note online', (tester) async {
      await open(tester);
      expect(find.byKey(const Key('offline-note')), findsNothing);
    });

    testWidgets('nothing loaded yet and offline: a connection is needed the first time', (tester) async {
      await open(tester, children: const [], offline: true);
      expect(find.text('محتاجين إنترنت أول مرة عشان نحمّل البيانات.'), findsOneWidget);
    });
  });

  group('never blank (bug 0003)', () {
    Future<ScreenHarness> openWith(WidgetTester tester, List<Override> extra, {Guardian? guardian, bool children = true}) async {
      final h = ScreenHarness(
        initial: '/children',
        routes: [GoRoute(path: '/children', builder: (_, _) => const MyChildScreen())],
        overrides: [...profileOverrides(children: const [], guardian: guardian, includeChildren: children), ...extra],
      );
      await h.pump(tester);
      return h;
    }

    testWidgets('a failed read shows the error with «حاولي تاني», which reads again', (tester) async {
      var reads = 0;
      final h = await openWith(tester, children: false, [
        childrenProvider.overrideWith((ref) {
          reads++;
          return Stream.error(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'));
        }),
      ]);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('load-error')), findsOneWidget);
      expect(find.text('حاولي تاني'), findsOneWidget);
      final before = reads;
      await tester.tap(find.byKey(const Key('load-retry')));
      await tester.pump();
      expect(reads, greaterThan(before));
      h.container.dispose();
    });

    testWidgets('no children: the empty state with «إضافة طفل», and «ربط أطفال العيادة» when the clinic has some', (tester) async {
      await openWith(tester, const [], guardian: const Guardian(
        uid: 'g3',
        phone: '+201000000003',
        fullName: 'محمد',
        relation: Relation.mother,
        consentVersion: 1,
        clinicChildrenPending: true,
      ));
      expect(find.byKey(const Key('add-child')), findsOneWidget);
      expect(find.byKey(const Key('link-clinic-children')), findsOneWidget);
      expect(find.text('ربط أطفال العيادة'), findsOneWidget);
    });
  });
}
