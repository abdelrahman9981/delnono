import '../data/doses_repository.dart';
import '../data/vaccine_schedule_repository.dart';
import 'child_age.dart';

/// D-17. Facts about the schedule date, not medical judgments.
enum DoseState { scheduled, due, given, late, missed }

/// One basic dose of a child's schedule with its computed state (research R3).
class ScheduledDose {
  const ScheduledDose({required this.entry, required this.dueDate, required this.state, this.record});

  final ScheduleEntry entry;

  /// `YYYY-MM-DD`.
  final String dueDate;
  final DoseState state;
  final DoseRecord? record;
}

/// The state of [entry] for a child born on [birthDate], on [today] (Cairo dates):
/// given if recorded; else scheduled before the due date; missed after the last allowed age (if
/// set); late more than [lateAfterDays] after the due date; otherwise due.
ScheduledDose scheduledDose(
  ScheduleEntry entry, {
  required String birthDate,
  required String today,
  required List<DoseRecord> records,
  required int lateAfterDays,
}) {
  final dueDate = addAge(birthDate, entry.dueAge);
  final record = records.where((r) => r.scheduleId == entry.id).firstOrNull;
  final DoseState state;
  if (record != null) {
    state = DoseState.given;
  } else if (compareDates(today, dueDate) < 0) {
    state = DoseState.scheduled;
  } else if (entry.lastAge != null && compareDates(today, addAge(birthDate, entry.lastAge!)) > 0) {
    state = DoseState.missed;
  } else if (daysBetween(dueDate, today) > lateAfterDays) {
    state = DoseState.late;
  } else {
    state = DoseState.due;
  }
  return ScheduledDose(entry: entry, dueDate: dueDate, state: state, record: record);
}

/// The child's basic schedule in order, grouped by the schedule's age label.
List<(String, List<ScheduledDose>)> scheduleFor(
  List<ScheduleEntry> schedule, {
  required String birthDate,
  required String today,
  required List<DoseRecord> records,
  required int lateAfterDays,
}) {
  final groups = <(String, List<ScheduledDose>)>[];
  for (final e in schedule) {
    final dose = scheduledDose(e, birthDate: birthDate, today: today, records: records, lateAfterDays: lateAfterDays);
    if (groups.isNotEmpty && groups.last.$1 == e.ageLabel) {
      groups.last.$2.add(dose);
    } else {
      groups.add((e.ageLabel, [dose]));
    }
  }
  return groups;
}

/// Doses recorded for an additional vaccine, by dose number. Additional vaccines have no late or
/// missed state: they are optional (FR-010).
List<DoseRecord> additionalDoses(String vaccineId, List<DoseRecord> records) =>
    records.where((r) => r.scheduleId == null && r.vaccineId == vaccineId).toList()
      ..sort((a, b) => a.dose.compareTo(b.dose));
