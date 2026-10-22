// End-to-end sign-in against the Firebase emulators (quickstart.md scenarios 2 and 7).
//
//   functions/node_modules/.bin/firebase emulators:start --only auth,firestore,functions \
//     --import=./emulator-seed
//   flutter test integration_test/sign_in_test.dart --dart-define=USE_EMULATOR=true -d <simulator>

import 'dart:convert';
import 'dart:io';

import 'package:delnono/app/app.dart';
import 'package:delnono/app/router.dart';
import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const testPhone = '+201000000099';
final authHost = Platform.isAndroid ? '10.0.2.2:9099' : 'localhost:9099';

/// The Auth emulator never sends SMS; it lists the codes it issued.
Future<String> latestCodeFor(String phone) async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(
      Uri.parse('http://$authHost/emulator/v1/projects/demo-delnono/verificationCodes'),
    );
    final res = await req.close();
    final body = jsonDecode(await res.transform(utf8.decoder).join()) as Map<String, dynamic>;
    final codes = (body['verificationCodes'] as List).cast<Map<String, dynamic>>();
    return codes.lastWhere((c) => c['phoneNumber'] == phone)['code'] as String;
  } finally {
    client.close();
  }
}

Future<void> deleteAllEmulatorUsers() async {
  final client = HttpClient();
  try {
    final req = await client.deleteUrl(
      Uri.parse('http://$authHost/emulator/v1/projects/demo-delnono/accounts'),
    );
    await (await req.close()).drain<void>();
  } finally {
    client.close();
  }
}

String location(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(App)))
    .read(routerProvider)
    .routerDelegate
    .currentConfiguration
    .uri
    .toString();

/// Pumps frames until [done] holds (real time, so network calls can finish).
Future<void> settle(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    expect(useEmulator, isTrue, reason: 'Run with --dart-define=USE_EMULATOR=true');
    await initFirebase();
    await deleteAllEmulatorUsers();
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('sign in with a code, then stay signed in after a restart (FR-003, FR-005, FR-010)',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    // A protected tab sends a signed-out visitor to sign-in, remembering where they were going.
    await tester.tap(find.text('حجز'));
    await settle(tester, () => find.byKey(const Key('phone-field')).evaluate().isNotEmpty);
    expect(location(tester), '/sign-in?from=%2Fbooking');

    await tester.enterText(find.byKey(const Key('phone-field')), '010 0000 0099');
    await tester.tap(find.text('ابعتيلي الكود'));
    await settle(tester, () => find.byKey(const Key('otp-field')).evaluate().isNotEmpty);
    expect(location(tester), '/sign-in/code?from=%2Fbooking');

    await tester.enterText(find.byKey(const Key('otp-field')), await latestCodeFor(testPhone));
    await settle(tester, () => location(tester).startsWith('/register'));

    expect(FirebaseAuth.instance.currentUser?.phoneNumber, testPhone);
    // No guardian doc yet, so the guard continues to registration with `from` kept.
    expect(location(tester), '/register/guardian?from=%2Fbooking');

    // Restart the widget tree with a fresh provider container: the session persists (FR-010).
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(ProviderScope(key: UniqueKey(), child: const App()));
    await tester.pumpAndSettle();
    expect(FirebaseAuth.instance.currentUser?.phoneNumber, testPhone);

    await tester.tap(find.text('حجز'));
    await settle(tester, () => location(tester).startsWith('/register'));
    expect(location(tester), '/register/guardian?from=%2Fbooking', reason: 'not sent back to sign-in');
  });
}
