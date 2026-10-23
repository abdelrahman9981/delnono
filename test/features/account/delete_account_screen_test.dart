import 'package:delnono/features/account/data/account_api.dart';
import 'package:delnono/features/account/presentation/delete_account_screen.dart';
import 'package:delnono/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/screen_harness.dart';

class _Api implements AccountApi {
  int deletes = 0;
  Object? error;

  @override
  Future<void> deleteAccount() async {
    if (error != null) throw error!;
    deletes++;
  }

  @override
  Future<void> syncPhoneNumber() async {}
}

class _Auth extends Mock implements AuthRepository {
  int signOuts = 0;

  @override
  Future<void> signOut() async => signOuts++;
}

void main() {
  late _Api api;
  late _Auth auth;

  Future<ScreenHarness> open(WidgetTester tester) async {
    api = _Api();
    auth = _Auth();
    final h = ScreenHarness(
      initial: '/account/delete',
      routes: [GoRoute(path: '/account/delete', builder: (_, _) => const DeleteAccountScreen())],
      overrides: [accountApiProvider.overrideWithValue(api), authRepositoryProvider.overrideWithValue(auth)],
    );
    await h.pump(tester);
    return h;
  }

  FilledButton button(WidgetTester tester) => tester.widget<FilledButton>(find.byKey(const Key('delete-button')));

  testWidgets('explains what is removed and what the clinic keeps', (tester) async {
    await open(tester);
    expect(find.text('ملفات أطفالك الطبية وسجل موافقتك، للمدة اللي يحددها القانون.'), findsOneWidget);
    expect(find.textContaining('حسابك ورقمك واسمك'), findsOneWidget);
  });

  testWidgets('nothing is called before the explicit confirmation', (tester) async {
    await open(tester);
    await scrollTo(tester, find.byKey(const Key('delete-button')));
    expect(button(tester).onPressed, isNull);
    await tester.tap(find.byKey(const Key('delete-button')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(api.deletes, 0);
  });

  testWidgets('confirmed: deletes, signs out and returns to Welcome', (tester) async {
    final h = await open(tester);
    await tapVisible(tester, find.byKey(const Key('delete-confirm')));
    await tapVisible(tester, find.byKey(const Key('delete-button')));
    expect(api.deletes, 1);
    expect(auth.signOuts, 1);
    expect(h.location, '/welcome');
    expect(find.text('اتمسح حسابك.'), findsOneWidget);
  });

  testWidgets('a server error stays on the screen without signing out', (tester) async {
    final h = await open(tester);
    api.error = Exception('offline');
    await tapVisible(tester, find.byKey(const Key('delete-confirm')));
    await tapVisible(tester, find.byKey(const Key('delete-button')));
    expect(auth.signOuts, 0);
    expect(h.location, '/account/delete');
    expect(find.text('حصلت مشكلة. جربي تاني.'), findsOneWidget);
  });
}
