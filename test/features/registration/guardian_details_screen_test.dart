import 'package:delnono/app/session_flags.dart';
import 'package:delnono/features/registration/application/registration_controller.dart';
import 'package:delnono/features/registration/data/guardian_repository.dart';
import 'package:delnono/features/registration/data/registration_api.dart';
import 'package:delnono/features/registration/presentation/guardian_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/screen_harness.dart';
import 'fakes.dart';

void main() {
  late FakeRegistrationApi api;

  Future<ScreenHarness> open(WidgetTester tester) async {
    api = FakeRegistrationApi();
    final h = ScreenHarness(
      initial: '/register/guardian?from=%2Fbooking',
      routes: [
        GoRoute(
          path: '/register/guardian',
          builder: (_, s) => GuardianDetailsScreen(from: s.uri.queryParameters['from']),
        ),
      ],
      overrides: [registrationApiProvider.overrideWithValue(api)],
    );
    await h.pump(tester);
    return h;
  }

  Future<void> next(WidgetTester tester) => tapVisible(tester, find.text('التالي'));

  testWidgets('shows the design text', (tester) async {
    await open(tester);
    expect(find.text('نتعرف عليكي'), findsOneWidget);
    expect(find.text('أم'), findsOneWidget);
    expect(find.text('مش هنحفظ أي بيانات غير بعد ما توافقي على سياسة الخصوصية في الخطوة الجاية.'), findsOneWidget);
  });

  testWidgets('name and relation are required; nothing is kept or sent', (tester) async {
    final h = await open(tester);
    await next(tester);
    expect(find.text('اكتبي اسمك بالكامل، من حرفين لحد ٨٠ حرف.'), findsOneWidget);
    expect(find.text('اختاري صلة القرابة.'), findsOneWidget);
    expect(h.container.read(registrationControllerProvider).details, isNull);
    expect(h.location, '/register/guardian?from=%2Fbooking');
  });

  testWidgets('a one-letter name and a bad email are refused', (tester) async {
    await open(tester);
    await tester.enterText(find.byKey(const Key('guardian-name')), 'س');
    await tester.enterText(find.byKey(const Key('guardian-email')), 'not-an-email');
    await next(tester);
    expect(find.text('اكتبي اسمك بالكامل، من حرفين لحد ٨٠ حرف.'), findsOneWidget);
    expect(find.text('الإيميل مش مكتوب صح.'), findsOneWidget);
  });

  testWidgets('valid details stay in memory and open consent, keeping from (FR-015)', (tester) async {
    final h = await open(tester);
    await tester.enterText(find.byKey(const Key('guardian-name')), '  سارة محمود ');
    await tapVisible(tester, find.text('أم'));
    await next(tester);

    final details = h.container.read(registrationControllerProvider).details!;
    expect(details.fullName, 'سارة محمود');
    expect(details.relation, Relation.mother);
    expect(details.email, isNull, reason: 'email is optional');
    expect(h.container.read(registrationInProgressProvider), isTrue);
    expect(api.registrations, isEmpty, reason: 'nothing is sent before consent');
    expect(h.location, '/register/consent?from=%2Fbooking');
  });
}
