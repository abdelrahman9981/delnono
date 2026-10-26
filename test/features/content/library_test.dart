import 'package:delnono/core/clock.dart';
import 'package:delnono/features/auth/data/auth_repository.dart';
import 'package:delnono/features/children/data/children_repository.dart';
import 'package:delnono/features/child_profile/application/selected_child.dart';
import 'package:delnono/features/content/domain/content_item.dart';
import 'package:delnono/features/content/presentation/library_screen.dart';
import 'package:delnono/features/content/presentation/tip_screen.dart';
import 'package:delnono/features/content/presentation/video_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/screen_harness.dart';
import '../child_profile/fakes.dart' show MemorySelectedChildStore, mariam, salma, today;
import 'fakes.dart';

class _User extends Mock implements User {
  @override
  String get uid => 'u1';
}

void main() {
  late List<String> opened;

  Future<ScreenHarness> open(
    WidgetTester tester, {
    List<ContentItem>? items,
    List<Child>? children,
    bool online = true,
    String initial = '/content',
  }) async {
    opened = [];
    final h = ScreenHarness(
      initial: initial,
      routes: [
        GoRoute(path: '/content', builder: (_, _) => const LibraryScreen()),
        GoRoute(path: '/content/tip/:id', builder: (_, s) => TipScreen(id: s.pathParameters['id']!)),
        GoRoute(path: '/content/video/:id', builder: (_, s) => VideoScreen(id: s.pathParameters['id']!)),
      ],
      overrides: [
        ...contentOverrides(items: items ?? sampleContent, online: online, opened: opened),
        clockProvider.overrideWithValue(() => today),
        authStateProvider.overrideWith((ref) => Stream.value(children == null ? null : _User())),
        childrenProvider.overrideWith((ref) => Stream.value(children ?? const <Child>[])),
        selectedChildStoreProvider.overrideWithValue(MemorySelectedChildStore()),
      ],
    );
    await h.pump(tester);
    return h;
  }

  Finder item(String id) => find.byKey(Key('content-item-$id'));

  testWidgets('signed out: published items, chips, footer; no age section (US1)', (tester) async {
    await open(tester);
    for (final id in ['salt', 'vitd', 'tip-fever', 'newborn']) {
      await scrollTo(tester, item(id));
      expect(item(id), findsOneWidget);
    }
    expect(find.byKey(const Key('content-for-age')), findsNothing);
    expect(find.byKey(const Key('chip-fever')), findsOneWidget);
    expect(find.text('الرضاعة والهضم'), findsWidgets);
    await scrollTo(tester, find.text('كل المحتوى بيراجعه الدكتور قبل النشر.'));
  });

  testWidgets('a category chip filters; «الكل» shows everything', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('chip-sleep')));
    await tester.pumpAndSettle();
    expect(item('vitd'), findsOneWidget);
    expect(item('salt'), findsNothing);
    expect(item('tip-fever'), findsNothing);
    await tester.tap(find.byKey(const Key('chip-allergy')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('content-no-results')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chip-all')));
    await tester.pumpAndSettle();
    expect(item('salt'), findsOneWidget);
  });

  testWidgets('search matches titles across hamza and taa marbuta forms', (tester) async {
    await open(tester);
    await tester.enterText(find.byKey(const Key('content-search')), 'الولاده');
    await tester.pumpAndSettle();
    expect(item('newborn'), findsOneWidget);
    expect(item('salt'), findsNothing);
    await tester.enterText(find.byKey(const Key('content-search')), 'ملح');
    await tester.pumpAndSettle();
    expect(item('salt'), findsOneWidget);
    expect(item('newborn'), findsNothing);
  });

  testWidgets('no published content: a clear empty note', (tester) async {
    await open(tester, items: const []);
    expect(find.byKey(const Key('content-empty')), findsOneWidget);
  });

  testWidgets('a tip opens its text; placeholders stay in brackets', (tester) async {
    final h = await open(tester);
    await tapVisible(tester, item('tip-fever'));
    expect(h.location, '/content/tip/tip-fever');
    expect(find.byKey(const Key('tip-body')), findsOneWidget);
    expect(find.text('[نص النصيحة · يكتبه الدكتور قبل النشر]'), findsOneWidget);
  });

  testWidgets('a video plays in a vertical 9:16 player; on an embed error it offers YouTube', (tester) async {
    final h = await open(tester);
    await tapVisible(tester, item('salt'));
    expect(h.location, '/content/video/salt');
    final player = find.byKey(const Key('player-WjbDIjEH38U'));
    expect(player, findsOneWidget);
    final ratio = tester.widget<AspectRatio>(find.ancestor(of: player, matching: find.byType(AspectRatio)).first);
    expect(ratio.aspectRatio, 9 / 16);
    final size = tester.getSize(player);
    expect(size.height, greaterThan(size.width), reason: 'Shorts are vertical');
    await tester.tap(player);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('video-unavailable')), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-youtube')));
    expect(opened, ['WjbDIjEH38U']);
  });

  testWidgets('offline: the list still opens and a video says it needs internet (US3)', (tester) async {
    await open(tester, online: false);
    expect(item('salt'), findsOneWidget);
    await tapVisible(tester, item('salt'));
    expect(find.byKey(const Key('video-offline')), findsOneWidget);
    expect(find.byKey(const Key('player-WjbDIjEH38U')), findsNothing);
  });

  testWidgets('a removed item says it is no longer available', (tester) async {
    await open(tester, initial: '/content/video/gone');
    expect(find.byKey(const Key('content-not-found')), findsOneWidget);
  });

  testWidgets("«مناسب لسن سلمى»: items covering a 9-month-old's age (US2)", (tester) async {
    await open(tester, children: const [salma]);
    expect(find.text('مناسب لسن سلمى'), findsOneWidget);
    expect(find.byKey(const Key('age-salt')), findsOneWidget);
    expect(find.byKey(const Key('age-vitd')), findsOneWidget);
    expect(find.byKey(const Key('age-newborn')), findsNothing, reason: '0–1 months');
    expect(find.byKey(const Key('age-tip-fever')), findsNothing, reason: 'no age range');
  });

  testWidgets('no age section for a child over 4 years', (tester) async {
    await open(tester, children: const [mariam]);
    expect(find.byKey(const Key('content-for-age')), findsNothing);
  });

  testWidgets('no age section when signed in without children', (tester) async {
    await open(tester, children: const []);
    expect(find.byKey(const Key('content-for-age')), findsNothing);
  });
}
