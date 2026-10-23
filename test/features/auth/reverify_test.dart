import 'package:delnono/app/session_flags.dart';
import 'package:delnono/core/widgets/birth_date_picker.dart';
import 'package:delnono/features/auth/application/session_controller.dart';
import 'package:delnono/features/auth/data/auth_repository.dart';
import 'package:delnono/features/auth/data/session_api.dart';
import 'package:delnono/features/auth/presentation/reverify_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/screen_harness.dart';

class _Api implements SessionApi {
  bool required = true;
  int touches = 0;
  Object? touchError;
  final attempts = <String>[];
  Object? reverifyResult;

  @override
  Future<bool> touchSession() async {
    touches++;
    if (touchError != null) throw touchError!;
    return required;
  }

  @override
  Future<void> reverifyGuardian(String birthDate) async {
    attempts.add(birthDate);
    if (reverifyResult != null) throw reverifyResult!;
  }
}

class _Auth extends Mock implements AuthRepository {
  int signOuts = 0;

  @override
  Future<void> signOut() async => signOuts++;
}

void main() {
  group('SessionController (FR-010a)', () {
    late _Api api;
    late ProviderContainer c;

    setUp(() {
      api = _Api();
      c = ProviderContainer(overrides: [sessionApiProvider.overrideWithValue(api)]);
      addTearDown(c.dispose);
    });

    test('raises the re-check flag when the server requires it', () async {
      await c.read(sessionControllerProvider.notifier).check('u1');
      expect(c.read(reverifyRequiredProvider), isTrue);
    });

    test('checks once per uid per app start', () async {
      await c.read(sessionControllerProvider.notifier).check('u1');
      await c.read(sessionControllerProvider.notifier).check('u1');
      expect(api.touches, 1);
      await c.read(sessionControllerProvider.notifier).check('u2');
      expect(api.touches, 2);
    });

    test('a failed check (e.g. offline) is retried next time and does not raise the flag', () async {
      api.touchError = Exception('offline');
      await c.read(sessionControllerProvider.notifier).check('u1');
      expect(c.read(reverifyRequiredProvider), isFalse);
      api.touchError = null;
      await c.read(sessionControllerProvider.notifier).check('u1');
      expect(api.touches, 2);
      expect(c.read(reverifyRequiredProvider), isTrue);
    });

    test('reverified and reset lower the flag', () async {
      await c.read(sessionControllerProvider.notifier).check('u1');
      c.read(sessionControllerProvider.notifier).reverified();
      expect(c.read(reverifyRequiredProvider), isFalse);
      await c.read(sessionControllerProvider.notifier).check('u1');
      c.read(sessionControllerProvider.notifier).reset();
      expect(c.read(sessionControllerProvider), isNull);
    });
  });

  group('ReverifyScreen (FR-010b)', () {
    late _Api api;
    late _Auth auth;

    Future<ScreenHarness> open(WidgetTester tester) async {
      api = _Api();
      auth = _Auth();
      final h = ScreenHarness(
        initial: '/reverify?from=%2Fchildren',
        routes: [GoRoute(path: '/reverify', builder: (_, s) => ReverifyScreen(from: s.uri.queryParameters['from']))],
        overrides: [
          sessionApiProvider.overrideWithValue(api),
          authRepositoryProvider.overrideWithValue(auth),
          birthDatePickerProvider.overrideWithValue((context, {initial}) async => DateTime(2024, 3, 15)),
        ],
      );
      h.container.read(reverifyRequiredProvider.notifier).set(true);
      await h.pump(tester);
      return h;
    }

    Future<void> pickAndConfirm(WidgetTester tester) async {
      await tapVisible(tester, find.byKey(const Key('reverify-birth-date')));
      await tapVisible(tester, find.text('تأكيد'));
    }

    testWidgets('a correct date lifts the flag', (tester) async {
      final h = await open(tester);
      await pickAndConfirm(tester);
      expect(api.attempts, ['2024-03-15']);
      expect(h.container.read(reverifyRequiredProvider), isFalse);
    });

    testWidgets('a wrong date shows the attempts left', (tester) async {
      final h = await open(tester);
      api.reverifyResult = const ReverifyWrongBirthDate(2);
      await pickAndConfirm(tester);
      expect(
        find.text('التاريخ مش مطابق. فاضلك محاولتين. بعدها هنقفل بيانات الأطفال لحد ما تكلمي العيادة.'),
        findsOneWidget,
      );
      expect(h.container.read(reverifyRequiredProvider), isTrue);
    });

    testWidgets('locked: says to contact the clinic and disables confirm', (tester) async {
      await open(tester);
      api.reverifyResult = const ReverifyLocked();
      await pickAndConfirm(tester);
      expect(find.text('قفلنا بيانات الأطفال بعد المحاولات دي. كلمي العيادة عشان نفتحها تاني.'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'تأكيد')).onPressed, isNull);
    });

    testWidgets('sign out is always available', (tester) async {
      final h = await open(tester);
      await tapVisible(tester, find.text('تسجيل الخروج'));
      expect(auth.signOuts, 1);
      expect(h.location, '/welcome');
      expect(h.container.read(reverifyRequiredProvider), isFalse);
    });
  });
}
