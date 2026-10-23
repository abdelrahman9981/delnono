// Shared helpers for end-to-end tests against the Firebase emulators.

import 'dart:convert';
import 'dart:io';

import 'package:delnono/app/app.dart';
import 'package:delnono/app/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

final emulatorHost = Platform.isAndroid ? '10.0.2.2' : 'localhost';

Future<Object?> _request(String method, String url) async {
  final client = HttpClient();
  try {
    final req = await client.openUrl(method, Uri.parse(url));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    return body.isEmpty ? null : jsonDecode(body);
  } finally {
    client.close();
  }
}

/// The Auth emulator never sends SMS; it lists the codes it issued.
Future<String> latestCodeFor(String phone) async {
  final body = await _request('GET', 'http://$emulatorHost:9099/emulator/v1/projects/demo-delnono/verificationCodes')
      as Map<String, dynamic>;
  final codes = (body['verificationCodes'] as List).cast<Map<String, dynamic>>();
  return codes.lastWhere((c) => c['phoneNumber'] == phone)['code'] as String;
}

Future<void> deleteAllEmulatorUsers() =>
    _request('DELETE', 'http://$emulatorHost:9099/emulator/v1/projects/demo-delnono/accounts');

String location(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(App)))
    .read(routerProvider)
    .routerDelegate
    .currentConfiguration
    .uri
    .toString();

/// Pumps frames until [done] holds (real time, so network calls can finish).
Future<void> settle(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 150 && !done(); i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

bool shows(Finder f) => f.evaluate().isNotEmpty;

/// Scrolls the current screen's list until [finder] is built, then taps it.
Future<void> tapInList(WidgetTester tester, Finder finder) async {
  final list = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(finder, 120, scrollable: list);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
}

/// Starts the app fresh (new provider container; Firebase keeps its session).
Future<void> startApp(WidgetTester tester, {List<Override> overrides = const []}) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(ProviderScope(key: UniqueKey(), overrides: overrides, child: const App()));
  await tester.pumpAndSettle();
}

/// A signed-out launch starts at Welcome; "browse content first" enters the app's tabs.
Future<void> leaveWelcome(WidgetTester tester) async {
  final browse = find.text('اتفرجي على المحتوى الأول');
  if (!shows(browse)) return;
  await tester.tap(browse);
  await settle(tester, () => shows(find.text('حجز')));
}

/// From Welcome or any shell screen: Booking → sign in with [phone] and the emulator's code.
Future<void> signInFromBooking(WidgetTester tester, String phone) async {
  await leaveWelcome(tester);
  await tester.tap(find.text('حجز'));
  await settle(tester, () => shows(find.byKey(const Key('phone-field'))));
  await tester.enterText(find.byKey(const Key('phone-field')), phone.substring(3));
  await tester.tap(find.text('ابعتيلي الكود'));
  await settle(tester, () => shows(find.byKey(const Key('otp-field'))));
  await tester.enterText(find.byKey(const Key('otp-field')), await latestCodeFor(phone));
  await settle(tester, () => location(tester).startsWith('/register'));
}

/// Guardian details and both consents, ending wherever the guard sends a new guardian next.
Future<void> registerGuardian(WidgetTester tester, String name) async {
  await tester.enterText(find.byKey(const Key('guardian-name')), name);
  await tapInList(tester, find.text('أم'));
  await tapInList(tester, find.text('التالي'));
  await settle(tester, () => shows(find.byKey(const Key('consent-policy'))));
  await tapInList(tester, find.byKey(const Key('consent-policy')));
  await tapInList(tester, find.byKey(const Key('consent-child-data')));
  await tapInList(tester, find.text('موافقة ومتابعة'));
}
