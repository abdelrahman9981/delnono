// The guardian app as the D-43 web demo, in a browser against the emulators: signed out content, sign
// in with the demo family 0201 and 123456 (the emulator build's code swap, D-51), book a visit,
// «طفلي», a Short in the web player, «حسابي» without phone-only notifications. At desktop width the
// app sits in the phone frame. Run by scripts/dashboard_e2e.sh at phone and desktop sizes.

import 'package:delnono/app/app.dart';
import 'package:delnono/app/router.dart';
import 'package:delnono/app/splash_intro.dart';
import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:delnono/features/content/presentation/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

Future<void> settle(WidgetTester tester, bool Function() done, {int seconds = 40}) async {
  for (var i = 0; i < seconds * 5 && !done(); i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

bool shows(Finder f) => f.evaluate().isNotEmpty;

String location(WidgetTester tester) {
  final config = ProviderScope.containerOf(tester.element(find.byType(App))).read(routerProvider).routerDelegate.currentConfiguration;
  return config.last is ImperativeRouteMatch ? config.last.matchedLocation : config.uri.toString();
}

Future<void> tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(f);
  await tester.pump(const Duration(milliseconds: 500));
}

/// Scrolls the screen's list until [f] is built (lists build lazily), then taps it.
Future<void> tapInList(WidgetTester tester, Finder f) async {
  final list = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(f, 200, scrollable: list);
  await tap(tester, f);
}

Finder keysStarting(String prefix) =>
    find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith(prefix));

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(useEmulator, isTrue, reason: 'Run with --dart-define=USE_EMULATOR=true');
    await initFirebase();
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('web demo: content, sign in with 123456, book, «طفلي», a Short, «حسابي»', (tester) async {
    final errors = <String>[];
    final report = FlutterError.onError;
    FlutterError.onError = (details) {
      // A debug-only engine assertion when a test types into a field the browser has not focused;
      // not an app error.
      if ('${details.exception}'.contains('text editing strategy is not currently')) return;
      errors.add(details.toString());
      binding.reportData = {'errors': errors};
      report?.call(details);
    };
    await tester.pumpWidget(ProviderScope(overrides: [splashEnabledProvider.overrideWithValue(false)], child: const App()));
    await tester.pump(const Duration(seconds: 1));

    // Phone frame on a wide window only (D-43).
    final wide = tester.view.physicalSize.width / tester.view.devicePixelRatio >= 600;
    expect(shows(find.byKey(const Key('web-phone-frame'))), wide);

    // Signed out: content first.
    await settle(tester, () => shows(find.text('اتفرجي على المحتوى الأول')));
    await tap(tester, find.text('اتفرجي على المحتوى الأول'));
    await settle(tester, () => shows(keysStarting('content-item-')));
    expect(keysStarting('content-item-'), findsWidgets);

    // Sign in from Booking with the demo family's test number and 123456.
    await tap(tester, find.text('حجز').last);
    await settle(tester, () => shows(find.byKey(const Key('phone-field'))));
    await tester.enterText(find.byKey(const Key('phone-field')), '1000000201');
    await tap(tester, find.text('ابعتيلي الكود'));
    await settle(tester, () => shows(find.byKey(const Key('otp-field'))));
    await tester.enterText(find.byKey(const Key('otp-field')), '123456');
    await settle(tester, () => location(tester) == '/booking');
    expect(location(tester), '/booking');

    // Book a visit a few days ahead (the family's preferred clinic may already be chosen).
    await settle(tester, () => shows(find.byKey(const Key('clinic-clinic-1'))) || shows(keysStarting('day-')));
    // The preferred clinic is picked a moment after the list shows; tap only if it is still needed.
    await settle(tester, () => shows(keysStarting('day-')), seconds: 5);
    if (!shows(keysStarting('day-'))) await tap(tester, find.byKey(const Key('clinic-clinic-1')));
    await settle(tester, () => shows(keysStarting('day-')));
    await tap(tester, keysStarting('day-').at(3));
    await settle(tester, () => shows(keysStarting('hour-')));
    await tap(tester, keysStarting('hour-').first);
    await tap(tester, keysStarting('child-').first);
    await tapInList(tester, find.byKey(const Key('confirm-booking')));
    await settle(tester, () => shows(find.byKey(const Key('booking-number'))));
    expect(location(tester), startsWith('/booking/done/'));

    // «طفلي»: the family's children.
    await tap(tester, find.text('طفلي').last);
    await settle(tester, () => shows(find.textContaining('آدم')));
    expect(find.textContaining('آدم'), findsWidgets);

    // A Short in the web player.
    await tap(tester, find.text('محتوى').last);
    await settle(tester, () => shows(keysStarting('content-item-')));
    await tapInList(tester, find.byKey(const Key('content-item-yt-WjbDIjEH38U')));
    await settle(tester, () => shows(find.byType(ShortPlayer)));
    expect(find.byType(ShortPlayer), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tap(tester, find.byType(BackButton));
    await settle(tester, () => location(tester) == '/content');

    // «حسابي»: the guardian; no phone notifications on the web.
    await tap(tester, find.text('حسابي').last);
    await settle(tester, () => shows(find.byKey(const Key('me-guardian'))));
    expect(find.byKey(const Key('me-guardian')), findsOneWidget);
    expect(find.byKey(const Key('me-notifications')), findsNothing);
    expect(find.byKey(const Key('notifications-bell')), findsNothing);
    expect(errors, isEmpty);
  });
}
