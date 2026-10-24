import 'package:delnono/core/clock.dart';
import 'package:delnono/features/booking/data/booking_api.dart';
import 'package:delnono/features/booking/data/booking_settings.dart';
import 'package:delnono/features/booking/data/slots_repository.dart';
import 'package:delnono/features/booking/data/vaccines_repository.dart';
import 'package:delnono/features/booking/domain/price_preview.dart';
import 'package:delnono/features/booking/presentation/booking_screen.dart';
import 'package:delnono/features/children/data/children_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/screen_harness.dart';
import 'fakes.dart';

// Sunday 15 Nov 2026, 12:00 Cairo. Open: Sat–Thu 17–21; vaccine days Mon (16th) and Wed (18th).
final now = DateTime.utc(2026, 11, 15, 10);
const kids = [
  Child(id: 'a', name: 'يوسف', birthDate: '2026-02-01', sex: Sex.male),
  Child(id: 'b', name: 'مريم', birthDate: '2023-06-01', sex: Sex.female),
];
const vaccines = [
  Vaccine(id: 'v1', name: '[تطعيم ١]', price: 150, showPrice: true),
  Vaccine(id: 'v3', name: '[تطعيم ٣]', price: 450, showPrice: false),
];

void main() {
  late FakeBookingApi api;

  Future<ScreenHarness> open(
    WidgetTester tester, {
    List<Child> children = kids,
    Map<int, int> taken = const {17: 6, 18: 2},
    BookingSettings settings = const BookingSettings(),
  }) async {
    api = FakeBookingApi();
    final h = ScreenHarness(
      initial: '/booking',
      routes: [GoRoute(path: '/booking', builder: (_, _) => const BookingScreen())],
      overrides: [
        clockProvider.overrideWithValue(() => now),
        bookingSettingsProvider.overrideWith((ref) => Stream.value(settings)),
        childrenProvider.overrideWith((ref) => Stream.value(children)),
        vaccinesProvider.overrideWith((ref) => Stream.value(vaccines)),
        slotsTakenProvider.overrideWith((ref, date) => Stream.value(taken)),
        bookingApiProvider.overrideWithValue(api),
      ],
    );
    await h.pump(tester);
    return h;
  }

  Future<void> pick(WidgetTester tester, Key key) => tapVisible(tester, find.byKey(key));

  testWidgets('closed days are not offered; Friday 20 Nov is missing', (tester) async {
    await open(tester);
    expect(find.byKey(const Key('day-2026-11-15')), findsOneWidget);
    expect(find.byKey(const Key('day-2026-11-20')), findsNothing);
  });

  testWidgets('hours show places left; a full hour is "مكتمل" and cannot be picked (FR-003)', (tester) async {
    await open(tester);
    await pick(tester, const Key('day-2026-11-15'));
    expect(find.text('مكتمل'), findsOneWidget); // 17:00, 6 of 6 taken
    expect(find.text('فاضل ٤ من ٦'), findsOneWidget); // 18:00
    expect(find.text('٦ لـ ٧ م'), findsOneWidget);
    await pick(tester, const Key('hour-17'));
    expect(find.byKey(const Key('booking-summary')), findsNothing, reason: 'full hour not selected');
  });

  testWidgets('places left never show below zero when capacity was lowered', (tester) async {
    await open(tester, settings: const BookingSettings(capacityPerHour: 1), taken: const {18: 3});
    await pick(tester, const Key('day-2026-11-15'));
    expect(find.textContaining('-'), findsNothing);
  });

  testWidgets('two siblings: one visit price, and confirm sends the shown total', (tester) async {
    await open(tester);
    await pick(tester, const Key('day-2026-11-15'));
    await pick(tester, const Key('hour-18'));
    await pick(tester, const Key('child-a'));
    await pick(tester, const Key('child-b'));
    expect(tester.widget<Text>(find.byKey(const Key('summary-total'))).data, '٣٠٠ جنيه');
    await pick(tester, const Key('confirm-booking'));
    final (sel, total) = api.created.single;
    expect(sel.date, '2026-11-15');
    expect(sel.hour, 18);
    expect(sel.children.keys, ['a', 'b']);
    expect(total, 300);
  });

  testWidgets('"الميعاد اتحجز" on a full hour; the hour is cleared and the rest kept (FR-009)', (tester) async {
    await open(tester);
    await pick(tester, const Key('day-2026-11-15'));
    await pick(tester, const Key('hour-18'));
    await pick(tester, const Key('child-a'));
    api.error = const BookingFullException();
    await pick(tester, const Key('confirm-booking'));
    expect(find.text('الميعاد اتحجز. اختاري ساعة تانية.'), findsOneWidget);
    expect(find.byKey(const Key('booking-summary')), findsNothing);
  });

  testWidgets('price changed: the new total is shown and she confirms again (FR-015)', (tester) async {
    await open(tester);
    await pick(tester, const Key('day-2026-11-15'));
    await pick(tester, const Key('hour-18'));
    await pick(tester, const Key('child-a'));
    api.error = const BookingPriceChangedException(
      PriceSnapshot(visitAmount: 350, visitCovered: false, vaccines: [], total: 350, hasHiddenPrices: false),
    );
    await pick(tester, const Key('confirm-booking'));
    expect(find.text('السعر اتغير. الإجمالي دلوقتي ٣٥٠ جنيه، أكدي تاني.'), findsOneWidget);
  });

  testWidgets('same day and limit errors in Arabic', (tester) async {
    await open(tester);
    await pick(tester, const Key('day-2026-11-15'));
    await pick(tester, const Key('hour-18'));
    await pick(tester, const Key('child-a'));
    api.error = const BookingSameDayException('x');
    await pick(tester, const Key('confirm-booking'));
    expect(find.text('عندك حجز في اليوم ده بالفعل. عدّليه لو عايزة تضيفي طفل.'), findsOneWidget);
  });

  testWidgets('no children: a prompt to add one', (tester) async {
    await open(tester, children: const []);
    expect(find.text('ضيفي طفل الأول عشان تحجزي.'), findsOneWidget);
  });

  group('US3 vaccines', () {
    testWidgets('vaccine only offers only vaccine days (Mon 16, Wed 18)', (tester) async {
      await open(tester);
      await pick(tester, const Key('type-vaccine'));
      expect(find.byKey(const Key('day-2026-11-15')), findsNothing);
      expect(find.byKey(const Key('day-2026-11-16')), findsOneWidget);
      expect(find.byKey(const Key('day-2026-11-18')), findsOneWidget);
    });

    testWidgets('vaccines are picked per child; vaccine only totals vaccine prices', (tester) async {
      await open(tester);
      await pick(tester, const Key('type-vaccine'));
      await pick(tester, const Key('day-2026-11-16'));
      await pick(tester, const Key('hour-18'));
      await pick(tester, const Key('child-a'));
      await pick(tester, const Key('child-b'));
      expect(find.text('اختاري تطعيم واحد على الأقل.'), findsOneWidget);
      await pick(tester, const Key('vaccine-a-v1'));
      expect(tester.widget<Text>(find.byKey(const Key('summary-total'))).data, '١٥٠ جنيه');
      await pick(tester, const Key('confirm-booking'));
      final (sel, total) = api.created.single;
      expect(sel.visitType, VisitType.vaccineOnly);
      expect(sel.children, {'a': ['v1'], 'b': <String>[]});
      expect(total, 150);
    });

    testWidgets('a visit on a vaccine day can add vaccines; hidden prices say "بالسعر في العيادة"', (tester) async {
      await open(tester);
      await pick(tester, const Key('day-2026-11-16'));
      await pick(tester, const Key('hour-18'));
      await pick(tester, const Key('child-a'));
      await pick(tester, const Key('vaccine-a-v3'));
      expect(tester.widget<Text>(find.byKey(const Key('summary-total'))).data, '٣٠٠ جنيه');
      expect(find.text('بالسعر في العيادة'), findsOneWidget);
      expect(find.text('الإجمالي من غير التطعيمات اللي سعرها في العيادة.'), findsOneWidget);
    });

    testWidgets('no vaccine picker on a day that is not a vaccine day', (tester) async {
      await open(tester);
      await pick(tester, const Key('day-2026-11-15'));
      await pick(tester, const Key('hour-18'));
      await pick(tester, const Key('child-a'));
      expect(find.byKey(const Key('vaccine-a-v1')), findsNothing);
    });
  });
}
