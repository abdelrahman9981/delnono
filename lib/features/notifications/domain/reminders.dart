import '../../../app/l10n/app_localizations.dart';
import '../../../core/format/arabic_digits.dart';
import '../../booking/domain/booking.dart';
import '../../booking/domain/clinic_time.dart';
import '../../booking/presentation/booking_format.dart';
import '../../child_profile/data/doses_repository.dart';
import '../../child_profile/data/vaccine_schedule_repository.dart';
import '../../child_profile/domain/child_age.dart';
import '../../children/data/children_repository.dart';

// Reminder times from the BRD: bookings a day and an hour before (D-18); vaccines 3 days before and
// on the day (D-17), at 09:00 Cairo time.
const bookingReminderOffsets = {'24h': Duration(hours: 24), '1h': Duration(hours: 1)};
const vaccineReminderDaysBefore = {'3d': 3, 'day': 0};
const vaccineReminderHour = 9;

/// iOS keeps at most 64 pending notifications; the nearest 50 are scheduled (research R1).
const maxScheduled = 50;

/// The page shows what happened in the last 60 days (research R4).
const feedWindow = Duration(days: 60);

enum ReminderKind { booking, vaccine }

/// One reminder that should exist, past or future (data-model.md).
class Reminder {
  const Reminder({required this.key, required this.kind, required this.at, required this.title, required this.body, required this.route});

  /// Stable across rebuilds (research R2): `booking:{id}:24h`, `vaccine:{child}:{dose}:3d`.
  final String key;
  final ReminderKind kind;
  final DateTime at;
  final String title;
  final String body;

  /// Where tapping it goes: My bookings, or the child's vaccines.
  final String route;

  int get id => reminderId(key);
}

/// The data reminders are planned from.
class ReminderInputs {
  const ReminderInputs({
    required this.bookings,
    required this.children,
    required this.schedule,
    required this.catalogue,
    required this.doses,
  });

  final List<Booking> bookings;
  final List<Child> children;
  final List<ScheduleEntry> schedule;
  final Map<String, VaccineInfo> catalogue;

  /// Recorded doses by child id.
  final Map<String, List<DoseRecord>> doses;
}

/// A 31-bit FNV-1a hash of [key]: the plugin's notification id.
int reminderId(String key) {
  var h = 0x811c9dc5;
  for (final unit in key.codeUnits) {
    h ^= unit;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h & 0x7fffffff;
}

const myBookingsRoute = '/booking/mine';
String childVaccinesRoute(String childId) => '/children/$childId/vaccines';

/// Every reminder the data calls for, past and future, before the guardian's switches (FR-001,
/// FR-002). Bookings: confirmed or later, never cancelled or no-show. Vaccines: basic doses not
/// given, and the next dose of each additional series the family started (FR-45).
List<Reminder> planReminders(ReminderInputs i, AppLocalizations l10n) {
  final out = <Reminder>[];
  for (final b in i.bookings) {
    if (b.status == BookingStatus.cancelled || b.status == BookingStatus.noShow) continue;
    if (b.status == BookingStatus.done || b.status == BookingStatus.arrived) continue;
    final body = '${bookingTitle(l10n, b)} · ${weekdayName(b.date)} ${hourRange(l10n, b.hour)}';
    for (final MapEntry(key: tag, value: before) in bookingReminderOffsets.entries) {
      out.add(Reminder(
        key: 'booking:${b.id}:$tag',
        kind: ReminderKind.booking,
        at: b.startsAt.subtract(before),
        title: tag == '24h' ? l10n.remindBookingDay : l10n.remindBookingHour,
        body: body,
        route: myBookingsRoute,
      ));
    }
  }
  for (final child in i.children) {
    final records = i.doses[child.id] ?? const <DoseRecord>[];
    void vaccine(String doseKey, String vaccineId, int dose, String due) {
      final name = i.catalogue[vaccineId]?.name ?? vaccineId;
      final label = dose > 1 ? l10n.remindVaccineDose(name, arabicDigits(dose)) : name;
      for (final MapEntry(key: tag, value: daysBefore) in vaccineReminderDaysBefore.entries) {
        out.add(Reminder(
          key: 'vaccine:${child.id}:$doseKey:$tag',
          kind: ReminderKind.vaccine,
          at: ClinicTime.startsAt(ClinicTime.addDays(due, -daysBefore), vaccineReminderHour),
          title: tag == 'day' ? l10n.remindVaccineToday(child.name) : l10n.remindVaccineSoon(child.name),
          body: l10n.remindVaccineBody(label, dayLabel(due)),
          route: childVaccinesRoute(child.id),
        ));
      }
    }

    for (final e in i.schedule) {
      if (records.any((r) => r.scheduleId == e.id)) continue;
      vaccine(e.id, e.vaccineId, e.dose, addAge(child.birthDate, e.dueAge));
    }
    final started = {for (final r in records) if (r.scheduleId == null) r.vaccineId};
    for (final vaccineId in started) {
      final info = i.catalogue[vaccineId];
      if (info == null || info.kind != VaccineKind.additional || info.intervalWeeks <= 0) continue;
      final last = records.where((r) => r.scheduleId == null && r.vaccineId == vaccineId).reduce((a, b) => a.dose >= b.dose ? a : b);
      if (last.dose >= info.doses) continue;
      vaccine('$vaccineId#${last.dose + 1}', vaccineId, last.dose + 1, ClinicTime.addDays(last.givenOn, info.intervalWeeks * 7));
    }
  }
  return out;
}

/// What goes on the phone (FR-003, FR-005): future reminders of the types turned on, the nearest
/// [maxScheduled].
List<Reminder> toSchedule(List<Reminder> all, {required DateTime now, required bool booking, required bool vaccine}) {
  final on = all
      .where((r) => r.at.isAfter(now) && (r.kind == ReminderKind.booking ? booking : vaccine))
      .toList()
    ..sort((a, b) => a.at.compareTo(b.at));
  return on.take(maxScheduled).toList();
}

enum FeedKind { bookingReminder, vaccineReminder, confirmed, cancelled }

/// One line of the notifications page.
class FeedItem {
  const FeedItem({
    required this.key,
    required this.kind,
    required this.at,
    required this.title,
    required this.body,
    required this.route,
  });

  final String key;
  final FeedKind kind;
  final DateTime at;
  final String title;
  final String body;
  final String route;
}

/// The page (FR-007): reminders whose time came (whatever the switches), booking confirmations
/// (a change confirms the new time: a new item) and cancellations, newest first, last 60 days.
List<FeedItem> feedItems(List<Reminder> all, List<Booking> bookings, AppLocalizations l10n, {required DateTime now}) {
  final since = now.subtract(feedWindow);
  bool inWindow(DateTime t) => !t.isAfter(now) && t.isAfter(since);
  final items = <FeedItem>[
    for (final r in all)
      if (inWindow(r.at))
        FeedItem(
          key: r.key,
          kind: r.kind == ReminderKind.booking ? FeedKind.bookingReminder : FeedKind.vaccineReminder,
          at: r.at,
          title: r.title,
          body: r.body,
          route: r.route,
        ),
    for (final b in bookings) ...[
      if ((b.updatedAt ?? b.createdAt) case final t? when inWindow(t))
        FeedItem(
          key: 'confirmed:${b.id}:${b.startsAt.millisecondsSinceEpoch}',
          kind: FeedKind.confirmed,
          at: t,
          title: l10n.eventBookingConfirmed,
          body: '${bookingTitle(l10n, b)} · ${dayLabel(b.date)}',
          route: myBookingsRoute,
        ),
      if (b.status == BookingStatus.cancelled && b.cancelledAt != null && inWindow(b.cancelledAt!))
        FeedItem(
          key: 'cancelled:${b.id}',
          kind: FeedKind.cancelled,
          at: b.cancelledAt!,
          title: l10n.eventBookingCancelled,
          body: '${bookingTitle(l10n, b)} · ${dayLabel(b.date)}',
          route: myBookingsRoute,
        ),
    ],
  ]..sort((a, b) => b.at.compareTo(a.at));
  return items;
}
