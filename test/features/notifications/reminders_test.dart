import 'package:delnono/app/l10n/app_localizations.dart';
import 'package:delnono/features/booking/domain/booking.dart';
import 'package:delnono/features/booking/domain/clinic_time.dart';
import 'package:delnono/features/booking/domain/price_preview.dart';
import 'package:delnono/features/child_profile/data/doses_repository.dart';
import 'package:delnono/features/child_profile/data/vaccine_schedule_repository.dart';
import 'package:delnono/features/child_profile/domain/child_age.dart';
import 'package:delnono/features/children/data/children_repository.dart';
import 'package:delnono/features/notifications/domain/reminders.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Sunday 15 Nov 2026, 12:00 Cairo.
final now = DateTime.utc(2026, 11, 15, 10);
final l10n = lookupAppLocalizations(const Locale('ar'));

Booking booking(String id, String date, int hour, {BookingStatus status = BookingStatus.confirmed, DateTime? createdAt, DateTime? cancelledAt}) =>
    Booking(
      id: id,
      clinicId: 'clinic-1',
      number: 1,
      visitType: VisitType.visit,
      children: const [BookedChild(childId: 'c1', name: 'يوسف', vaccines: [])],
      date: date,
      hour: hour,
      startsAt: ClinicTime.startsAt(date, hour),
      status: status,
      price: const PriceSnapshot(visitAmount: 300, visitCovered: false, vaccines: [], total: 300, hasHiddenPrices: false),
      createdAt: createdAt,
      cancelledAt: cancelledAt,
    );

const youssef = Child(id: 'c1', name: 'يوسف', birthDate: '2026-07-20', sex: Sex.male);
// Due at 4 months: 2026-11-20 (5 days from now).
const fourMonths = ScheduleEntry(id: 's4', vaccineId: 'v1', dose: 1, dueAge: AgeSpan(months: 4), ageLabel: '٤ شهور', order: 1);
// Due at 2 months: 2026-09-20 (past).
const twoMonths = ScheduleEntry(id: 's2', vaccineId: 'v1', dose: 1, dueAge: AgeSpan(months: 2), ageLabel: 'شهرين', order: 0);
const catalogue = {
  'v1': VaccineInfo(id: 'v1', name: '[الخماسي]', kind: VaccineKind.basic),
  'rota': VaccineInfo(id: 'rota', name: '[الروتا]', kind: VaccineKind.additional, doses: 2, intervalWeeks: 4),
  'flu': VaccineInfo(id: 'flu', name: '[الأنفلونزا]', kind: VaccineKind.additional, doses: 2, intervalWeeks: 4),
};

ReminderInputs inputs({List<Booking> bookings = const [], List<DoseRecord> doses = const [], List<ScheduleEntry> schedule = const [fourMonths]}) =>
    ReminderInputs(bookings: bookings, children: const [youssef], schedule: schedule, catalogue: catalogue, doses: {'c1': doses});

List<String> keys(List<Reminder> r) => r.map((x) => x.key).toList();

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  group('booking reminders (US1, D-18)', () {
    test('a day and an hour before a confirmed booking', () {
      final r = planReminders(inputs(schedule: const [], bookings: [booking('b', '2026-11-17', 18)]), l10n);
      expect(keys(r), ['booking:b:24h', 'booking:b:1h']);
      final day = r.firstWhere((x) => x.key == 'booking:b:24h');
      expect(day.at, ClinicTime.startsAt('2026-11-16', 18));
      expect(day.title, 'ميعادك بكرة');
      expect(day.body, contains('يوسف'));
      expect(day.route, '/booking/mine');
      expect(r.firstWhere((x) => x.key == 'booking:b:1h').at, ClinicTime.startsAt('2026-11-17', 17));
    });

    test('cancelled, done and no-show bookings get none', () {
      final r = planReminders(inputs(schedule: const [], bookings: [
        booking('x', '2026-11-17', 18, status: BookingStatus.cancelled),
        booking('d', '2026-11-10', 18, status: BookingStatus.done),
        booking('n', '2026-11-10', 18, status: BookingStatus.noShow),
      ]), l10n);
      expect(r, isEmpty);
    });
  });

  group('vaccine reminders (US2, D-17, FR-45)', () {
    test('3 days before and on the day at 09:00 Cairo for a basic dose not given', () {
      final r = planReminders(inputs(), l10n);
      expect(keys(r), ['vaccine:c1:s4:3d', 'vaccine:c1:s4:day']);
      expect(r[0].at, ClinicTime.startsAt('2026-11-17', 9));
      expect(r[1].at, ClinicTime.startsAt('2026-11-20', 9));
      expect(r[0].title, 'تطعيم يوسف بعد ٣ أيام');
      expect(r[1].title, 'تطعيم يوسف النهارده');
      expect(r[0].body, contains('[الخماسي]'));
      expect(r[0].route, '/children/c1/vaccines');
    });

    test('a given dose has none', () {
      final given = DoseRecord(id: 'd', scheduleId: 's4', vaccineId: 'v1', dose: 1, givenOn: '2026-11-14');
      expect(planReminders(inputs(doses: [given]), l10n), isEmpty);
    });

    test('the next dose of a started additional series, by its interval; none for one not started', () {
      final rota1 = DoseRecord(id: 'r', vaccineId: 'rota', dose: 1, givenOn: '2026-11-01');
      final r = planReminders(inputs(schedule: const [], doses: [rota1]), l10n);
      expect(keys(r), ['vaccine:c1:rota#2:3d', 'vaccine:c1:rota#2:day']);
      expect(r[1].at, ClinicTime.startsAt('2026-11-29', 9), reason: '2026-11-01 + 4 weeks');
      final done = DoseRecord(id: 'r2', vaccineId: 'rota', dose: 2, givenOn: '2026-11-29');
      expect(planReminders(inputs(schedule: const [], doses: [rota1, done]), l10n), isEmpty, reason: 'series complete');
    });
  });

  group('what goes on the phone', () {
    test('only future reminders of the types turned on, nearest first, at most 50', () {
      final all = planReminders(inputs(bookings: [booking('b', '2026-11-17', 18)], schedule: const [twoMonths, fourMonths]), l10n);
      expect(all.map((r) => r.key), contains('vaccine:c1:s2:day'), reason: 'past ones still planned for the page');
      final phone = toSchedule(all, now: now, booking: true, vaccine: true);
      expect(phone.every((r) => r.at.isAfter(now)), isTrue);
      expect(keys(phone), ['booking:b:24h', 'vaccine:c1:s4:3d', 'booking:b:1h', 'vaccine:c1:s4:day']);
      expect(keys(toSchedule(all, now: now, booking: true, vaccine: false)), ['booking:b:24h', 'booking:b:1h']);
      final many = [for (var i = 0; i < 40; i++) booking('b$i', '2026-12-${(i % 28 + 1).toString().padLeft(2, '0')}', 10 + i % 8)];
      expect(toSchedule(planReminders(inputs(bookings: many), l10n), now: now, booking: true, vaccine: true).length, 50);
    });

    test('ids are stable and differ per key', () {
      expect(reminderId('booking:b:24h'), reminderId('booking:b:24h'));
      expect(reminderId('booking:b:24h'), isNot(reminderId('booking:b:1h')));
      expect(reminderId('booking:b:24h'), inInclusiveRange(0, 0x7fffffff));
    });
  });

  group('the page (US3)', () {
    test('reminders whose time came, confirmations and cancellations, newest first, within 60 days', () {
      final all = planReminders(inputs(schedule: const [twoMonths], bookings: [
        booking('b', '2026-11-20', 18, createdAt: DateTime.utc(2026, 11, 14, 8)),
        booking('x', '2026-11-25', 18, status: BookingStatus.cancelled, createdAt: DateTime.utc(2026, 11, 1), cancelledAt: DateTime.utc(2026, 11, 15, 9)),
      ]), l10n);
      final feed = feedItems(all, [
        booking('b', '2026-11-20', 18, createdAt: DateTime.utc(2026, 11, 14, 8)),
        booking('x', '2026-11-25', 18, status: BookingStatus.cancelled, createdAt: DateTime.utc(2026, 11, 1), cancelledAt: DateTime.utc(2026, 11, 15, 9)),
      ], l10n, now: now);
      expect(feed.first.title, 'اتلغى حجزك');
      expect(feed.map((f) => f.title), contains('تم تأكيد حجزك'));
      expect(feed.map((f) => f.key), contains('vaccine:c1:s2:day'), reason: 'due 2026-09-20, within 60 days');
      expect(feed.map((f) => f.key), contains('vaccine:c1:s2:3d'), reason: '2026-09-17 is 59 days ago');
      final later = feedItems(all, const [], l10n, now: now.add(const Duration(days: 10)));
      expect(later.map((f) => f.key), isNot(contains('vaccine:c1:s2:3d')), reason: 'older than 60 days');
      expect(feed.every((f) => !f.at.isAfter(now)), isTrue);
    });
  });
}
