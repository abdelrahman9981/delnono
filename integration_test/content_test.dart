// The content library end to end against the Firebase emulators and the seeded channel videos
// (006 quickstart step 2): browse without an account, filter, search, read a tip, open a Short in
// the vertical player.
//
//   functions/node_modules/.bin/firebase emulators:start --only auth,firestore,functions \
//     --import=./emulator-seed
//   flutter test integration_test/content_test.dart --dart-define=USE_EMULATOR=true -d <simulator>

import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:delnono/features/content/presentation/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(useEmulator, isTrue, reason: 'Run with --dart-define=USE_EMULATOR=true');
    await initFirebase();
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('signed out: the library lists published items only; filter, search, a tip, a Short', (tester) async {
    await startApp(tester);
    await leaveWelcome(tester);
    await tester.tap(find.text('محتوى').last);
    await settle(tester, () => location(tester) == '/content');

    // Seed: 3 published Shorts and 3 placeholder tips; the 5 drafts never show (SC-003).
    Finder item(String id) => find.byKey(Key('content-item-$id'));
    await settle(tester, () => shows(item('yt-WjbDIjEH38U')));
    expect(item('yt-WjbDIjEH38U'), findsOneWidget);
    expect(find.byKey(const Key('chip-vaccines')), findsOneWidget, reason: 'the categories come from settings/content');

    await tester.tap(find.byKey(const Key('chip-sleep')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(item('yt-KDOV-4nbWqU'), findsOneWidget);
    expect(item('yt-WjbDIjEH38U'), findsNothing);
    await tester.tap(find.byKey(const Key('chip-all')));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byKey(const Key('content-search')), 'ملح');
    await tester.pump(const Duration(milliseconds: 300));
    expect(item('yt-WjbDIjEH38U'), findsOneWidget);
    expect(item('yt-TGzE9d9m44A'), findsNothing);
    await tester.enterText(find.byKey(const Key('content-search')), 'الحراره');
    await tester.pump(const Duration(milliseconds: 300));
    expect(item('yt-dHP05TFideE'), findsNothing, reason: 'a draft');
    expect(item('tip-fever'), findsOneWidget);

    // A tip opens its (bracketed) text.
    await tester.tap(item('tip-fever'));
    await settle(tester, () => shows(find.byKey(const Key('tip-body'))));
    expect(find.text('[نص النصيحة · يكتبه الدكتور قبل النشر]'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    // The location changes before the tip's page has left; wait for the library itself.
    await settle(tester, () => location(tester) == '/content' && shows(find.byKey(const Key('content-search'))));
    await tester.pump(const Duration(milliseconds: 500));

    // A Short plays in the app in a vertical 9:16 player, with the YouTube fallback offered.
    await tester.enterText(find.byKey(const Key('content-search')), '');
    await tester.pump(const Duration(milliseconds: 300));
    await tapInList(tester, item('yt-TGzE9d9m44A'));
    await settle(tester, () => shows(find.byType(ShortPlayer)));
    expect(location(tester), '/content/video/yt-TGzE9d9m44A');
    expect(find.byType(ShortPlayer), findsOneWidget);
    final size = tester.getSize(find.byType(ShortPlayer));
    expect(size.height / size.width, closeTo(16 / 9, 0.05));
    expect(find.byKey(const Key('open-youtube')), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const Key('video-unavailable')), findsNothing, reason: 'the Short allows embedding');
    await tester.tap(find.byType(BackButton));
    await settle(tester, () => location(tester) == '/content');
    expect(FirebaseAuth.instance.currentUser, isNull);
  });
}
