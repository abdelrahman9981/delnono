// RTL navigation: forward chevrons point left (‹), back buttons point right (›), and every
// pushed screen has a back button that returns to where the guardian was.

import 'package:delnono/app/app.dart';
import 'package:delnono/app/route_guard.dart';
import 'package:delnono/app/router.dart';
import 'package:delnono/core/launch/external_links.dart';
import 'package:delnono/core/settings/settings_repository.dart';
import 'package:delnono/features/account/data/account_api.dart';
import 'package:delnono/features/auth/data/auth_repository.dart';
import 'package:delnono/features/auth/data/phone_auth_service.dart';
import 'package:delnono/features/auth/data/session_api.dart';
import 'package:delnono/features/children/data/children_repository.dart';
import 'package:delnono/features/registration/data/guardian_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../features/auth/fakes.dart';
import '../features/child_profile/fakes.dart' show profileDataOverrides;
import '../features/registration/fakes.dart';
import '../helpers/rtl_icons.dart';

class _User extends Mock implements User {
  @override
  String get uid => 'u1';
}

class _Session implements SessionApi {
  @override
  Future<bool> touchSession() async => false;

  @override
  Future<void> reverifyGuardian(String birthDate) async {}
}

class _Account implements AccountApi {
  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> syncPhoneNumber() async {}
}

class _Links implements ExternalLinks {
  @override
  Future<bool> openWhatsApp(String e164) async => true;

  @override
  Future<bool> callNumber(String number) async => true;
}

const ready = GuardState(signedIn: true, hasGuardian: true, consentCurrent: true, hasChildren: true);
const guardian = Guardian(uid: 'u1', phone: '+201012345678', fullName: 'سارة', relation: Relation.mother, consentVersion: 1);
const kids = [Child(id: 'a', name: 'يوسف', birthDate: '2024-03-15', sex: Sex.male)];

void main() {
  late GoRouter router;

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        guardStateProvider.overrideWithValue(ready),
        authStateProvider.overrideWith((ref) => Stream.value(_User())),
        guardianProvider.overrideWith((ref) => Stream.value(guardian)),
        childrenProvider.overrideWith((ref) => Stream.value(kids)),
        authSettingsProvider.overrideWith((ref) => Stream.value(const AuthSettings())),
        policySettingsProvider.overrideWith((ref) => Stream.value(const PolicySettings(privacyPolicyText: 'x'))),
        sessionApiProvider.overrideWithValue(_Session()),
        accountApiProvider.overrideWithValue(_Account()),
        phoneAuthServiceProvider.overrideWithValue(FakePhoneAuthService()),
        childrenRepositoryProvider.overrideWithValue(FakeChildrenRepository()),
        externalLinksProvider.overrideWithValue(_Links()),
        ...profileDataOverrides(anyChild: true),
      ],
      child: const App(),
    ));
    await tester.pumpAndSettle();
    router = ProviderScope.containerOf(tester.element(find.byType(App))).read(routerProvider);
  }

  /// The screen on top: a pushed screen keeps the base URI, so read the last match.
  String location() => router.routerDelegate.currentConfiguration.last.matchedLocation;

  /// The screen has a back button that points right, and it returns to [backTo].
  Future<void> expectBackTo(WidgetTester tester, String backTo) async {
    final back = find.byType(BackButton);
    expect(back, findsOneWidget, reason: 'no back button on ${location()}');
    final icon = find.descendant(of: back, matching: find.byType(Icon));
    expect(pointing(tester.element(icon)), Pointing.right, reason: 'back must point right in RTL');
    expect(wrongWayIcons(tester), isEmpty);
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(location(), backTo);
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final f = find.byKey(Key(key));
    await tester.scrollUntilVisible(f, 120, scrollable: find.byType(Scrollable).last);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('Account opens from Home with a back button, and its rows point forward (‹)', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('account-button')));
    await tester.pumpAndSettle();
    expect(location(), Routes.account);

    final chevrons = find.descendant(of: find.byType(ListTile), matching: find.byType(Icon)).evaluate()
        .where((e) => pointing(e) != null)
        .toList();
    expect(chevrons, hasLength(5));
    for (final e in chevrons) {
      expect(pointing(e), Pointing.left, reason: 'forward chevron must point left in RTL');
    }
    await expectBackTo(tester, Routes.home);
  });

  testWidgets('screens opened from Account each have a back button to Account', (tester) async {
    await pumpApp(tester);
    for (final key in ['account-change-phone', 'account-notifications', 'account-delete']) {
      await tester.tap(find.byKey(const Key('account-button')));
      await tester.pumpAndSettle();
      await tapKey(tester, key);
      expect(location(), isNot(Routes.account), reason: key);
      await expectBackTo(tester, Routes.account);
      await expectBackTo(tester, Routes.home);
    }
  });

  testWidgets('My child entries point forward; each opens a screen with a back button to My child', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('طفلي'));
    await tester.pumpAndSettle();
    expect(wrongWayIcons(tester), isEmpty);
    for (final key in ['entry-vaccines', 'entry-visits', 'entry-follow-up', 'entry-details']) {
      final entry = find.byKey(Key(key));
      await tester.scrollUntilVisible(entry, 120, scrollable: find.byType(Scrollable).first);
      final chevron = find.descendant(of: entry, matching: find.byType(Icon)).last;
      expect(pointing(tester.element(chevron)), Pointing.left, reason: '$key must point forward (‹)');
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(location(), startsWith('/children/a'));
      await expectBackTo(tester, Routes.children);
    }

    await tapKey(tester, 'add-child');
    expect(location(), Routes.childrenAdd);
    await expectBackTo(tester, Routes.children);
  });
}
