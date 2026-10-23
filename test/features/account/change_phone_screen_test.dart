import 'package:delnono/core/settings/settings_repository.dart';
import 'package:delnono/features/account/data/account_api.dart';
import 'package:delnono/features/account/presentation/change_phone_screen.dart';
import 'package:delnono/features/auth/application/otp_controller.dart';
import 'package:delnono/features/auth/data/phone_auth_service.dart';
import 'package:delnono/features/registration/data/guardian_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/screen_harness.dart';
import '../auth/fakes.dart';

class _AccountApi implements AccountApi {
  int syncs = 0;

  @override
  Future<void> syncPhoneNumber() async => syncs++;

  @override
  Future<void> deleteAccount() async {}
}

void main() {
  late FakePhoneAuthService phone;
  late _AccountApi api;

  Future<ScreenHarness> open(WidgetTester tester) async {
    phone = FakePhoneAuthService();
    api = _AccountApi();
    final clock = FakeClock();
    final h = ScreenHarness(
      initial: '/account/phone',
      routes: [GoRoute(path: '/account/phone', builder: (_, _) => const ChangePhoneScreen())],
      overrides: [
        phoneAuthServiceProvider.overrideWithValue(phone),
        accountApiProvider.overrideWithValue(api),
        clockProvider.overrideWithValue(clock.call),
        authSettingsProvider.overrideWith((ref) => Stream.value(const AuthSettings())),
        guardianProvider.overrideWith((ref) => Stream.value(const Guardian(
              uid: 'u1',
              phone: '+201012345678',
              fullName: 'سارة',
              relation: Relation.mother,
              consentVersion: 1,
            ))),
      ],
    );
    await h.pump(tester);
    return h;
  }

  Future<void> sendTo(WidgetTester tester, String number) async {
    await tester.enterText(find.byKey(const Key('new-phone-field')), number);
    await tapVisible(tester, find.text('ابعتي الكود'));
  }

  testWidgets('the current number is refused before sending', (tester) async {
    await open(tester);
    await sendTo(tester, '01012345678');
    expect(find.text('ده نفس رقمك الحالي.'), findsOneWidget);
    expect(phone.sent, isEmpty);
  });

  testWidgets('a code on the new number changes it and syncs the account (FR-025)', (tester) async {
    final h = await open(tester);
    await sendTo(tester, '01112345678');
    expect(phone.sent.single.phone, '+201112345678');
    await tester.enterText(find.byKey(const Key('new-phone-otp-field')), '123456');
    await tester.pumpAndSettle();
    expect(phone.updates, ['123456']);
    expect(api.syncs, 1);
    expect(h.location, '/account');
  });

  testWidgets('a number with another account says to contact the clinic (FR-025a)', (tester) async {
    await open(tester);
    phone.updateError = FirebaseAuthException(code: 'credential-already-in-use');
    await sendTo(tester, '01112345678');
    await tester.enterText(find.byKey(const Key('new-phone-otp-field')), '123456');
    await tester.pumpAndSettle();
    expect(find.text('الرقم ده عليه حساب تاني. كلمي العيادة عشان نساعدك.'), findsOneWidget);
    expect(api.syncs, 0);
  });
}
