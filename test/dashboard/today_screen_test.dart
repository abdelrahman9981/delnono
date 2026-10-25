import 'package:delnono/dashboard/data/today_repository.dart';
import 'package:delnono/dashboard/screens/today_screen.dart';
import 'package:delnono/features/booking/data/booking_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/clinic_fakes.dart';
import 'fakes.dart';
import 'harness.dart';

void main() {
  late FakeDashboardApi api;

  Future<void> open(WidgetTester tester, {List<QueueBooking> bookings = const [], List<WalkIn> walkIns = const [], bool stopped = false, bool doctor = false}) async {
    api = FakeDashboardApi();
    await pumpDashboard(
      tester,
      const TodayScreen(),
      overrides: dashboardOverrides(api: api, bookings: bookings, walkIns: walkIns, stopped: stopped, session: doctor ? doctorSession : secretarySession),
    );
  }

  testWidgets('the calendar lists the working hours with places left (FR-005)', (tester) async {
    await open(tester, bookings: [queueBooking('a', 18), queueBooking('b', 18, number: 2)]);
    expect(find.byKey(const Key('hour-row-17')), findsOneWidget);
    expect(find.byKey(const Key('hour-row-20')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('hour-row-18')), matching: find.text('فاضل ٤ من ٦')), findsOneWidget);
  });

  testWidgets('marking a booking arrived calls queueAction (FR-006)', (tester) async {
    await open(tester, bookings: [queueBooking('a', 19)]);
    await tester.tap(find.byKey(const Key('arrive-a')));
    await tester.pumpAndSettle();
    expect(api.calls.single.$1, 'queueAction');
    expect(api.calls.single.$2, {'action': 'arrive', 'bookingId': 'a'});
  });

  testWidgets('no-show is offered only after the hour; undo only for the doctor', (tester) async {
    await open(tester, bookings: [queueBooking('past', 17), queueBooking('later', 20), queueBooking('done', 18, status: 'done', arrivedAt: now)]);
    expect(find.byKey(const Key('no-show-past')), findsOneWidget);
    expect(find.byKey(const Key('no-show-later')), findsNothing);
    expect(find.byKey(const Key('undo-done')), findsNothing);
  });

  testWidgets('the doctor can undo a status (005 clarification)', (tester) async {
    await open(tester, bookings: [queueBooking('done', 18, status: 'done', arrivedAt: now)], doctor: true);
    expect(find.byKey(const Key('undo-done')), findsOneWidget);
  });

  testWidgets('the queue is ordered by arrival time, walk-ins included, no priority (D-06, FR-060)', (tester) async {
    await open(
      tester,
      bookings: [queueBooking('late', 18, status: 'arrived', arrivedAt: now.add(const Duration(minutes: 5)))],
      walkIns: [WalkIn(id: 'w', hour: 18, familyName: 'عائلة', phone: '010', children: const ['سما'], status: 'arrived', arrivedAt: now)],
    );
    final walkIn = tester.getTopLeft(find.byKey(const Key('queue-w'))).dy;
    final late = tester.getTopLeft(find.byKey(const Key('queue-late'))).dy;
    expect(walkIn, lessThan(late));
    await tester.tap(find.byKey(const Key('done-w')));
    await tester.pumpAndSettle();
    expect(api.calls.single.$1, 'queueAction');
    expect(api.calls.single.$2, {'action': 'done', 'walkInId': 'w'});
  });

  testWidgets('adding a walk-in sends the hour, family and children (FR-007)', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('add-walk-in')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('walk-in-family')), 'أم سما');
    await tester.enterText(find.byKey(const Key('walk-in-phone')), '01000000055');
    await tester.enterText(find.byKey(const Key('walk-in-children')), 'سما، علي');
    await tester.tap(find.byKey(const Key('walk-in-save')));
    await tester.pumpAndSettle();
    final (name, data) = api.calls.single;
    expect(name, 'addWalkIn');
    expect(data['clinicId'], clinic1.id);
    expect(data['hour'], 18, reason: 'the first hour not over at 18:30');
    expect(data['children'], [{'name': 'سما'}, {'name': 'علي'}]);
  });

  testWidgets('stopped walk-ins disable the button; the switch sends the change (FR-008)', (tester) async {
    await open(tester, stopped: true);
    expect(tester.widget<FilledButton>(find.byKey(const Key('add-walk-in'))).onPressed, isNull);
    await tester.tap(find.byKey(const Key('stop-walk-ins')));
    await tester.pumpAndSettle();
    expect(api.calls.single.$1, 'setWalkInsStopped');
    expect(api.calls.single.$2['stopped'], false);
  });

  testWidgets('payment defaults to the fixed price and can be marked covered (FR-011)', (tester) async {
    await open(tester, bookings: [queueBooking('a', 18, status: 'done', arrivedAt: now)]);
    await tester.tap(find.byKey(const Key('pay-a')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '300'), findsOneWidget);
    await tester.tap(find.byKey(const Key('payment-covered')));
    await tester.enterText(find.byKey(const Key('payment-cash')), '0');
    await tester.tap(find.byKey(const Key('payment-save')));
    await tester.pumpAndSettle();
    expect(api.calls.single.$1, 'recordPayment');
    expect(api.calls.single.$2, {'bookingId': 'a', 'cash': 0, 'covered': true});
  });

  testWidgets('moving a booking sends the new day and hour with the same children (FR-009)', (tester) async {
    await open(tester, bookings: [queueBooking('a', 19)]);
    await tester.tap(find.byKey(const Key('booking-menu-a')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('move-a')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('move-hour-2026-11-15')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('٨ لـ ٩ م').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('move-save')));
    await tester.pumpAndSettle();
    final (name, data) = api.calls.single;
    expect(name, 'staffBookingAction');
    expect(data['action'], 'change');
    expect(data['selection'], {
      'visitType': 'visit',
      'date': '2026-11-15',
      'hour': 20,
      'children': [{'childId': 'c1', 'vaccines': <String>[]}],
    });
  });

  testWidgets('a clinic open all day fits: the hour filter scrolls, nothing overflows', (tester) async {
    api = FakeDashboardApi();
    await pumpDashboard(tester, const TodayScreen(), overrides: dashboardOverrides(
      api: api,
      clinic1Settings: const BookingSettings(workingHours: {7: [HourRange(0, 24)]}),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('hour-row-0')), findsOneWidget);
    expect(find.byKey(const Key('hour-row-23')), findsOneWidget);
  });
}
