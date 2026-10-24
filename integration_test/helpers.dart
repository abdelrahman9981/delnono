// Shared helpers for end-to-end tests against the Firebase emulators.

import 'dart:convert';
import 'dart:io';

import 'package:delnono/app/app.dart';
import 'package:delnono/app/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

/// The current location. A pushed screen (e.g. Account) keeps the base URI, so report its own
/// location instead.
String location(WidgetTester tester) {
  final config = ProviderScope.containerOf(tester.element(find.byType(App)))
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration;
  return config.last is ImperativeRouteMatch ? config.last.matchedLocation : config.uri.toString();
}

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
  // The router can report Welcome a frame before it is drawn (e.g. right after sign-out).
  await settle(tester, () => shows(browse) || shows(find.text('حجز')));
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
  await settle(tester, () => shows(find.byKey(const Key('guardian-name'))));
  await tester.enterText(find.byKey(const Key('guardian-name')), name);
  await tapInList(tester, find.text('أم'));
  await tapInList(tester, find.text('التالي'));
  await settle(tester, () => shows(find.byKey(const Key('consent-policy'))));
  await tapInList(tester, find.byKey(const Key('consent-policy')));
  await tapInList(tester, find.byKey(const Key('consent-child-data')));
  await tapInList(tester, find.text('موافقة ومتابعة'));
}

/// Writes [fields] (Firestore REST field values) to [path] through the Firestore emulator's admin
/// access, bypassing Security Rules. For test set-up the app itself is not allowed to do.
Future<void> adminSetFields(String path, Map<String, Object> fields) async {
  final mask = fields.keys.map((k) => 'updateMask.fieldPaths=$k').join('&');
  final client = HttpClient();
  try {
    final req = await client.patchUrl(Uri.parse(
      'http://$emulatorHost:8080/v1/projects/demo-delnono/databases/(default)/documents/$path?$mask',
    ));
    req.headers.set('Authorization', 'Bearer owner');
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({'fields': fields}));
    final res = await req.close();
    await res.drain<void>();
    if (res.statusCode != 200) throw StateError('adminSetFields $path: HTTP ${res.statusCode}');
  } finally {
    client.close();
  }
}

/// Sets a guardian's `lastActiveAt` [days] ago (the app may never write that field).
Future<void> ageGuardian(String uid, int days) => adminSetFields('guardians/$uid', {
      'lastActiveAt': {'timestampValue': DateTime.now().toUtc().subtract(Duration(days: days)).toIso8601String()},
    });

/// Widgets whose key is a `ValueKey<String>` starting with [prefix] (e.g. "day-"). Safe to wait on
/// with [shows]; use `.first` or `.last` only once they exist.
Finder keysStarting(String prefix) => find.byWidgetPredicate(
      (w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith(prefix),
    );

/// Registers a new guardian with one child [childName] (born on whatever the picker override returns),
/// starting from Welcome or the tabs; ends on Booking.
Future<void> registerWithChild(WidgetTester tester, String phone, String guardianName, String childName) async {
  await signInFromBooking(tester, phone);
  await registerGuardian(tester, guardianName);
  await settle(tester, () => shows(find.byKey(const Key('child-name'))));
  await tester.enterText(find.byKey(const Key('child-name')), childName);
  await tapInList(tester, find.byKey(const Key('child-birth-date')));
  await tapInList(tester, find.text('ولد'));
  await tapInList(tester, find.text('حفظ'));
  await settle(tester, () => location(tester) == '/booking');
}

/// Adds another child from the children list.
Future<void> addChild(WidgetTester tester, String name) async {
  await tester.tap(find.text('طفلي'));
  await settle(tester, () => shows(find.text('إضافة طفل')));
  await tapInList(tester, find.text('إضافة طفل'));
  await settle(tester, () => shows(find.byKey(const Key('child-name'))));
  await tester.enterText(find.byKey(const Key('child-name')), name);
  await tapInList(tester, find.byKey(const Key('child-birth-date')));
  await tapInList(tester, find.text('بنت'));
  await tapInList(tester, find.text('حفظ'));
  await settle(tester, () => shows(find.text(name)));
}
