import 'package:delnono/core/widgets/birth_date_picker.dart';
import 'package:delnono/features/child_profile/presentation/my_child_screen.dart';
import 'package:delnono/features/auth/data/auth_repository.dart';
import 'package:delnono/features/children/data/children_repository.dart';
import 'package:delnono/features/children/presentation/add_child_screen.dart';
import 'package:delnono/features/children/presentation/child_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:delnono/features/registration/data/guardian_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/screen_harness.dart';
import '../child_profile/fakes.dart' show profileDataOverrides;
import '../registration/fakes.dart';

class _User extends Mock implements User {
  @override
  String get uid => 'u1';
}

const youssef = Child(id: 'c1', name: 'يوسف', birthDate: '2024-03-15', sex: Sex.male, allergies: 'بنسلين', birthWeightKg: 3.2);

void main() {
  late FakeChildrenRepository repo;

  Future<ScreenHarness> open(WidgetTester tester, String initial, {List<Child> children = const [youssef]}) async {
    repo = FakeChildrenRepository();
    final h = ScreenHarness(
      initial: initial,
      routes: [
        GoRoute(path: '/children', builder: (_, _) => const MyChildScreen(), routes: [
          GoRoute(path: 'add', builder: (_, _) => const AddChildScreen()),
          GoRoute(path: ':id', builder: (_, s) => ChildProfileScreen(childId: s.pathParameters['id']!)),
        ]),
      ],
      overrides: [
        childrenRepositoryProvider.overrideWithValue(repo),
        childrenProvider.overrideWith((ref) => Stream.value(children)),
        authStateProvider.overrideWith((ref) => Stream.value(_User())),
        guardianProvider.overrideWith((ref) => Stream.value(null)),
        birthDatePickerProvider.overrideWithValue((context, {initial}) async => DateTime(2019, 1, 1)),
        ...profileDataOverrides(),
      ],
    );
    await h.pump(tester);
    return h;
  }

  group('my child', () {
    testWidgets('shows the linked child with their age and opens the details', (tester) async {
      final h = await open(tester, '/children');
      expect(find.text('يوسف'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('entry-details')));
      expect(h.location, '/children/c1');
    });

    testWidgets('empty state with an add button', (tester) async {
      final h = await open(tester, '/children', children: const []);
      expect(find.text('لسه مفيش أطفال في حسابك.'), findsOneWidget);
      await tapVisible(tester, find.text('إضافة طفل'));
      expect(h.location, '/children/add');
    });
  });

  group('child profile (FR-023, FR-024)', () {
    testWidgets('only name and allergies are editable; birth date and sex are read-only', (tester) async {
      await open(tester, '/children/c1');
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.byKey(const Key('profile-name')), findsOneWidget);
      expect(find.byKey(const Key('profile-allergies')), findsOneWidget);
      expect(find.text('١٥ مارس ٢٠٢٤'), findsOneWidget);
      expect(find.text('ولد'), findsOneWidget);
      expect(find.textContaining('كلمي العيادة'), findsOneWidget);
    });

    testWidgets('saving sends name and allergies with the editor', (tester) async {
      await open(tester, '/children/c1');
      await tester.enterText(find.byKey(const Key('profile-name')), ' يوسف أحمد ');
      await tester.enterText(find.byKey(const Key('profile-allergies')), '');
      await tapVisible(tester, find.text('حفظ'));
      expect(repo.updates.single, (childId: 'c1', uid: 'u1', name: 'يوسف أحمد', allergies: null));
      expect(find.text('اتحفظت التعديلات.'), findsOneWidget);
    });

    testWidgets('invalid values are not saved', (tester) async {
      await open(tester, '/children/c1');
      await tester.enterText(find.byKey(const Key('profile-name')), 'ي');
      await tapVisible(tester, find.text('حفظ'));
      expect(find.text('اكتبي اسم الطفل، من حرفين لحد ٦٠ حرف.'), findsOneWidget);
      expect(repo.updates, isEmpty);
    });

    testWidgets('an unknown child shows a message', (tester) async {
      await open(tester, '/children/nope');
      expect(find.text('الطفل ده مش موجود في حسابك.'), findsOneWidget);
    });
  });

  testWidgets('a child over 4 years can be added (FR-020)', (tester) async {
    await open(tester, '/children/add');
    await tester.enterText(find.byKey(const Key('child-name')), 'سلمى');
    await tapVisible(tester, find.byKey(const Key('child-birth-date')));
    await tapVisible(tester, find.text('بنت'));
    await tapVisible(tester, find.text('حفظ'));
    expect(repo.created.single.birthDate, '2019-01-01');
  });
}
