import 'package:delnono/app/session_flags.dart';
import 'package:delnono/features/children/data/children_repository.dart';
import 'package:delnono/features/children/presentation/add_child_screen.dart';
import 'package:delnono/features/registration/application/registration_controller.dart';
import 'package:delnono/features/registration/data/guardian_repository.dart';
import 'package:delnono/features/registration/data/registration_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/screen_harness.dart';
import '../registration/fakes.dart';

void main() {
  late FakeChildrenRepository repo;

  Future<ScreenHarness> open(WidgetTester tester, {bool registration = true}) async {
    repo = FakeChildrenRepository();
    final h = ScreenHarness(
      initial: registration ? '/register/child' : '/children/add',
      routes: [
        GoRoute(path: '/register/child', builder: (_, _) => const AddChildScreen(registration: true)),
        GoRoute(path: '/children/add', builder: (_, _) => const AddChildScreen()),
      ],
      overrides: [childrenRepositoryProvider.overrideWithValue(repo)],
    );
    await h.pump(tester);
    return h;
  }

  Future<void> fillValid(WidgetTester tester, {String name = 'يوسف'}) async {
    await tester.enterText(find.byKey(const Key('child-name')), name);
    await tapVisible(tester, find.byKey(const Key('child-birth-date')));
    // The picker opens on today; confirm it.
    final ok = MaterialLocalizations.of(tester.element(find.byType(DatePickerDialog))).okButtonLabel;
    await tester.tap(find.text(ok));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('ولد'));
  }

  Future<void> save(WidgetTester tester) => tapVisible(tester, find.text('حفظ'));

  testWidgets('name, birth date and sex are required', (tester) async {
    await open(tester);
    await save(tester);
    expect(find.text('اكتبي اسم الطفل، من حرفين لحد ٦٠ حرف.'), findsOneWidget);
    expect(find.text('اختاري تاريخ الميلاد.'), findsOneWidget);
    expect(find.text('اختاري النوع.'), findsOneWidget);
    expect(repo.created, isEmpty);
  });

  testWidgets('birth weight must be 0.3–7.0 kg; Arabic digits and decimal mark work', (tester) async {
    await open(tester);
    await fillValid(tester);
    await tester.enterText(find.byKey(const Key('child-weight')), '9');
    await save(tester);
    expect(find.text('الوزن لازم يكون بين ٠٫٣ و٧ كجم.'), findsOneWidget);
    expect(repo.created, isEmpty);

    await tester.enterText(find.byKey(const Key('child-weight')), '٣٫٢');
    await save(tester);
    expect(repo.created.single.birthWeightKg, 3.2);
  });

  testWidgets('allergies over 500 characters are refused', (tester) async {
    await open(tester);
    await fillValid(tester);
    await tester.enterText(find.byKey(const Key('child-allergies')), 'ا' * 501);
    await save(tester);
    expect(find.text('اكتبي الحساسية في أقل من ٥٠٠ حرف.'), findsOneWidget);
  });

  testWidgets('the vaccine-schedule note from the design is shown', (tester) async {
    await open(tester);
    expect(find.text('تاريخ الميلاد والنوع بيحددوا جدول التطعيمات، فتعديلهم بعد كده بيبقى من العيادة.'), findsOneWidget);
  });

  testWidgets('a duplicate already in the account shows a warning (FR-022)', (tester) async {
    await open(tester);
    repo.error = const DuplicateChildException(existingLinked: true);
    await fillValid(tester, name: 'مريم');
    await save(tester);
    expect(find.text('«مريم» متسجل في حسابك بنفس تاريخ الميلاد، فمش هنضيفه تاني.'), findsOneWidget);
  });

  testWidgets('a duplicate the clinic registered says to contact the clinic', (tester) async {
    await open(tester);
    repo.error = const DuplicateChildException(existingLinked: false);
    await fillValid(tester, name: 'مريم');
    await save(tester);
    expect(
      find.text('فيه طفل اسمه «مريم» بنفس تاريخ الميلاد مسجل على رقمك بالفعل، فمش هنضيفه تاني. لو ده غلط كلمي العيادة.'),
      findsOneWidget,
    );
  });

  testWidgets('saving the first child ends registration', (tester) async {
    final h = await open(tester);
    h.container.read(registrationControllerProvider.notifier).setDetails(
          const GuardianDetails(fullName: 'سارة', relation: Relation.mother),
        );
    expect(h.container.read(registrationInProgressProvider), isTrue);
    await fillValid(tester);
    await save(tester);
    expect(repo.created.single.name, 'يوسف');
    expect(h.container.read(registrationInProgressProvider), isFalse);
  });

  testWidgets('from the children list, saving returns to the list', (tester) async {
    final h = await open(tester, registration: false);
    await fillValid(tester);
    await save(tester);
    expect(h.location, '/children');
  });
}
