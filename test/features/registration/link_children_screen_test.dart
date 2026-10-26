import 'package:delnono/app/session_flags.dart';
import 'package:delnono/core/widgets/birth_date_picker.dart';
import 'package:delnono/features/registration/application/registration_controller.dart';
import 'package:delnono/features/registration/data/guardian_repository.dart';
import 'package:delnono/features/registration/data/registration_api.dart';
import 'package:delnono/features/registration/presentation/link_children_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/screen_harness.dart';
import 'fakes.dart';

void main() {
  late FakeRegistrationApi api;

  Future<ScreenHarness> open(WidgetTester tester, {bool inRegistration = true}) async {
    api = FakeRegistrationApi();
    final h = ScreenHarness(
      initial: '/register/link?from=%2Fbooking',
      routes: [
        GoRoute(path: '/register/link', builder: (_, s) => LinkChildrenScreen(from: s.uri.queryParameters['from'])),
      ],
      overrides: [
        registrationApiProvider.overrideWithValue(api),
        birthDatePickerProvider.overrideWithValue((context, {initial}) async => DateTime(2024, 3, 15)),
      ],
    );
    if (inRegistration) {
      h.container.read(registrationControllerProvider.notifier).setDetails(
            const GuardianDetails(fullName: 'سارة', relation: Relation.mother),
          );
    }
    await h.pump(tester);
    return h;
  }

  Future<void> pickAndConfirm(WidgetTester tester) async {
    await tapVisible(tester, find.byKey(const Key('link-birth-date')));
    await tapVisible(tester, find.text('تأكيد'));
  }

  testWidgets('nothing about the children is shown before the check (FR-021)', (tester) async {
    await open(tester);
    expect(find.text('فيه ملفات أطفال على رقمك'), findsOneWidget);
    expect(find.text('مش هنعرض أي بيانات غير لما الإجابة تبقى صح.'), findsOneWidget);
    expect(find.textContaining('يوسف'), findsNothing);
  });

  testWidgets('confirm is disabled until a date is picked, then sends it as YYYY-MM-DD', (tester) async {
    await open(tester);
    await scrollTo(tester, find.widgetWithText(FilledButton, 'تأكيد'));
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'تأكيد')).onPressed, isNull);
    await pickAndConfirm(tester);
    expect(api.linkAttempts, ['2024-03-15']);
  });

  testWidgets('a wrong date shows the attempts left', (tester) async {
    await open(tester);
    api.linkResult = const LinkWrongBirthDate(2);
    await pickAndConfirm(tester);
    expect(find.text('التاريخ مش مطابق. فاضلك محاولتين. بعدها هنوقف الربط وتقدري تكلمي العيادة.'), findsOneWidget);

    api.linkResult = const LinkWrongBirthDate(1);
    await tapVisible(tester, find.text('تأكيد'));
    expect(find.text('التاريخ مش مطابق. فاضلك محاولة واحدة. بعدها هنوقف الربط وتقدري تكلمي العيادة.'), findsOneWidget);
  });

  testWidgets('locked: says to contact the clinic (FR-021a)', (tester) async {
    await open(tester);
    api.linkResult = const LinkLocked();
    await pickAndConfirm(tester);
    expect(find.text('وقفنا الربط بعد المحاولات دي. كلمي العيادة عشان تربط أطفالك بحسابك.'), findsOneWidget);
  });

  testWidgets('success names the linked children and ends registration', (tester) async {
    final h = await open(tester);
    api.linkResult = const [LinkedChild('a', 'يوسف'), LinkedChild('b', 'مريم')];
    await pickAndConfirm(tester);
    expect(find.text('اتضاف يوسف ومريم لحسابك.'), findsOneWidget);
    expect(h.container.read(registrationInProgressProvider), isFalse);
  });

  testWidgets('a linked child the guardian had already added is flagged: ask the clinic to merge (FR-022)', (tester) async {
    await open(tester, inRegistration: false);
    api.linkResult = const [LinkedChild('a', 'يوسف', duplicate: true), LinkedChild('b', 'مريم')];
    await pickAndConfirm(tester);
    expect(find.textContaining('يوسف متسجل مرتين'), findsOneWidget);
  });

  testWidgets('"these aren\'t my children" skips without calling the function (US4 scenario 4)', (tester) async {
    final h = await open(tester);
    await tapVisible(tester, find.text('دول مش أطفالي · ضيفي طفل جديد'));
    expect(api.linkAttempts, isEmpty);
    expect(h.container.read(linkSkippedProvider), isTrue);
    expect(h.location, '/register/child?from=%2Fbooking');
  });

  testWidgets('outside registration, "not mine" opens add child', (tester) async {
    final h = await open(tester, inRegistration: false);
    await tapVisible(tester, find.text('دول مش أطفالي · ضيفي طفل جديد'));
    expect(h.location, '/children/add');
  });
}
