import 'package:delnono/core/clock.dart';
import 'package:delnono/core/launch/external_links.dart';
import 'package:delnono/features/booking/data/booking_api.dart';
import 'package:delnono/features/booking/data/bookings_repository.dart';
import 'package:delnono/features/booking/domain/booking.dart';
import 'package:delnono/features/booking/domain/price_preview.dart';
import 'package:delnono/features/booking/presentation/my_bookings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/clinic_fakes.dart';
import '../../helpers/screen_harness.dart';
import 'fakes.dart';

// Sunday 15 Nov 2026, 12:00 Cairo (10:00 UTC).
final now = DateTime.utc(2026, 11, 15, 10);

Booking booking(
  String id, {
  required String date,
  required int hour,
  BookingStatus status = BookingStatus.confirmed,
  int total = 300,
  int number = 1,
  String? clinicId,
}) {
  final p = date.split('-').map(int.parse).toList();
  return Booking(
    id: id,
    clinicId: clinicId,
    number: number,
    visitType: VisitType.visit,
    children: const [BookedChild(childId: 'a', name: 'يوسف', vaccines: [])],
    date: date,
    hour: hour,
    // Cairo is UTC+2 in November.
    startsAt: DateTime.utc(p[0], p[1], p[2], hour - 2),
    status: status,
    price: PriceSnapshot(visitAmount: 300, visitCovered: false, vaccines: const [], total: total, hasHiddenPrices: false),
  );
}

class _Links implements ExternalLinks {
  final opened = <String>[];

  @override
  Future<bool> openWhatsApp(String e164) async {
    opened.add(e164);
    return true;
  }

  @override
  Future<bool> callNumber(String number) async => true;
}

void main() {
  late FakeBookingApi api;
  late _Links links;

  Future<ScreenHarness> open(WidgetTester tester, List<Booking> bookings) async {
    api = FakeBookingApi();
    links = _Links();
    final h = ScreenHarness(
      initial: '/booking/mine',
      routes: [GoRoute(path: '/booking/mine', builder: (_, _) => const MyBookingsScreen())],
      overrides: [
        clockProvider.overrideWithValue(() => now),
        myBookingsProvider.overrideWith((ref) => Stream.value(bookings)),
        ...clinicOverrides(clinics: const [clinic1, clinic2], settings: const {'clinic-2': clinic2Settings}),
        bookingApiProvider.overrideWithValue(api),
        externalLinksProvider.overrideWithValue(links),
      ],
    );
    await h.pump(tester);
    return h;
  }

  group('US4 my bookings', () {
    testWidgets('upcoming soonest first; past in the other tab latest first (FR-018)', (tester) async {
      await open(tester, [
        booking('later', date: '2026-11-17', hour: 18, number: 3),
        booking('soonest', date: '2026-11-16', hour: 18, number: 2),
        booking('done', date: '2026-11-10', hour: 18, status: BookingStatus.done, number: 1),
        booking('cancelled', date: '2026-11-12', hour: 18, status: BookingStatus.cancelled, number: 4),
      ]);
      final soonest = tester.getTopLeft(find.byKey(const Key('booking-soonest'))).dy;
      final later = tester.getTopLeft(find.byKey(const Key('booking-later'))).dy;
      expect(soonest, lessThan(later));
      expect(find.byKey(const Key('booking-done')), findsNothing);

      await tapVisible(tester, find.byKey(const Key('tab-past')));
      expect(find.text('تم'), findsOneWidget);
      expect(find.text('ملغي'), findsOneWidget);
      final cancelled = tester.getTopLeft(find.byKey(const Key('booking-cancelled'))).dy;
      final done = tester.getTopLeft(find.byKey(const Key('booking-done'))).dy;
      expect(cancelled, lessThan(done));
    });

    testWidgets('shows number and the amount fixed at booking time (FR-015)', (tester) async {
      await open(tester, [booking('b', date: '2026-11-16', hour: 18, total: 450, number: 248)]);
      expect(find.text('# نونو ٢٤٨'), findsOneWidget);
      expect(find.text('٤٥٠ جنيه'), findsOneWidget);
      expect(find.text('كشف يوسف'), findsOneWidget);
    });

    testWidgets('a no-show is shown without a charge note', (tester) async {
      await open(tester, [booking('n', date: '2026-11-10', hour: 18, status: BookingStatus.noShow)]);
      await tapVisible(tester, find.byKey(const Key('tab-past')));
      expect(find.text('لم يحضر'), findsOneWidget);
    });

    testWidgets('empty state offers a new booking', (tester) async {
      final h = await open(tester, const []);
      expect(find.text('لسه مفيش حجوزات.'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('new-booking')));
      expect(h.location, '/booking');
    });
  });

  group('US5 cancel or change (FR-020, FR-021)', () {
    testWidgets('before the window: change and cancel; cancel asks first', (tester) async {
      final h = await open(tester, [booking('b', date: '2026-11-16', hour: 18)]);
      expect(find.text('لسه ينفع تعدلي أو تلغي'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('cancel-b')));
      expect(find.text('تلغي الحجز؟'), findsOneWidget);
      await tester.tap(find.text('لأ، خليه'));
      await tester.pumpAndSettle();
      expect(api.cancelled, isEmpty);

      await tapVisible(tester, find.byKey(const Key('cancel-b')));
      await tester.tap(find.byKey(const Key('confirm-cancel')));
      await tester.pumpAndSettle();
      expect(api.cancelled, ['b']);
      expect(find.text('اتلغى الحجز.'), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('change-b')));
      expect(h.location, '/booking/change/b');
    });

    testWidgets('inside a 3-hour window: "فاضل أقل من ٣ ساعات" and "كلمي العيادة"', (tester) async {
      await open(tester, [booking('s', date: '2026-11-15', hour: 14)]); // 2 h away
      expect(find.text('قريب'), findsOneWidget);
      expect(find.text('فاضل أقل من ٣ ساعات'), findsOneWidget);
      expect(find.byKey(const Key('cancel-s')), findsNothing);
      await tapVisible(tester, find.byKey(const Key('call-clinic-s')));
      expect(links.opened, ['+201000000000']);
    });

    testWidgets('a refusal inside the window is explained', (tester) async {
      await open(tester, [booking('b', date: '2026-11-16', hour: 18)]);
      api.error = const BookingRefusedException('inside_window');
      await tapVisible(tester, find.byKey(const Key('cancel-b')));
      await tester.tap(find.byKey(const Key('confirm-cancel')));
      await tester.pumpAndSettle();
      expect(find.textContaining('فاضل أقل من ٣ ساعات'), findsOneWidget);
    });
  });

  test('isUpcoming: confirmed until its hour ends; arrived only on its day', () {
    expect(isUpcoming(booking('x', date: '2026-11-15', hour: 12), now), isTrue, reason: '12–1 pm is under way at 12:00');
    expect(isUpcoming(booking('x', date: '2026-11-15', hour: 11), now), isFalse, reason: '11–12 has ended at 12:00');
    expect(isUpcoming(booking('x', date: '2026-11-15', hour: 9, status: BookingStatus.arrived), now), isTrue);
    expect(isUpcoming(booking('x', date: '2026-11-14', hour: 18, status: BookingStatus.arrived), now), isFalse);
  });

  group('004 two clinics', () {
    testWidgets('each card shows its clinic\'s name and address; old bookings show the main clinic (FR-009, FR-018)', (tester) async {
      await open(tester, [
        booking('a', date: '2026-11-16', hour: 18, clinicId: 'clinic-2'),
        booking('b', date: '2026-11-17', hour: 18),
      ]);
      expect(find.descendant(of: find.byKey(const Key('booking-a')), matching: find.text(clinic2.name)), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('booking-a')), matching: find.text(clinic2.address)), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('booking-b')), matching: find.text(clinic1.name)), findsOneWidget);
    });

    testWidgets('the cancel window and WhatsApp are the booking\'s clinic\'s (FR-010)', (tester) async {
      // 5 h away: outside clinic 1's 3 h window, inside clinic 2's 6 h window.
      await open(tester, [
        booking('one', date: '2026-11-15', hour: 17),
        booking('two', date: '2026-11-15', hour: 17, clinicId: 'clinic-2'),
      ]);
      expect(find.byKey(const Key('cancel-one')), findsOneWidget);
      expect(find.byKey(const Key('cancel-two')), findsNothing);
      await tapVisible(tester, find.byKey(const Key('call-clinic-two')));
      expect(links.opened, [clinic2.whatsapp]);
    });
  });
}
