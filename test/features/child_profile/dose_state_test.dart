import 'package:delnono/features/child_profile/data/doses_repository.dart';
import 'package:delnono/features/child_profile/data/vaccine_schedule_repository.dart';
import 'package:delnono/features/child_profile/domain/child_age.dart';
import 'package:delnono/features/child_profile/domain/dose_state.dart';
import 'package:flutter_test/flutter_test.dart';

// research R3 / SC-002: every boundary, the day before and after.
const birth = '2026-01-20';
const nineMonths = ScheduleEntry(id: 's06', vaccineId: 'v1', dose: 3, dueAge: AgeSpan(months: 9), ageLabel: 'ت', order: 5);
const withLimit = ScheduleEntry(
  id: 's08',
  vaccineId: 'v1',
  dose: 4,
  dueAge: AgeSpan(months: 2),
  lastAge: AgeSpan(months: 4),
  ageLabel: 'ث',
  order: 7,
);

DoseState stateOn(String today, {ScheduleEntry entry = nineMonths, List<DoseRecord> records = const [], int late = 7}) =>
    scheduledDose(entry, birthDate: birth, today: today, records: records, lateAfterDays: late).state;

void main() {
  test('due date comes from the birth date', () {
    expect(scheduledDose(nineMonths, birthDate: birth, today: '2026-10-24', records: const [], lateAfterDays: 7).dueDate,
        '2026-10-20');
  });

  final table = <(String, DoseState, String)>[
    ('2026-10-19', DoseState.scheduled, 'day before the due date'),
    ('2026-10-20', DoseState.due, 'on the due date'),
    ('2026-10-27', DoseState.due, 'exactly lateAfterDays after'),
    ('2026-10-28', DoseState.late, 'one day past the late threshold'),
    ('2027-06-01', DoseState.late, 'long after, no last allowed age'),
  ];
  for (final (today, expected, why) in table) {
    test('$expected $why ($today)', () => expect(stateOn(today), expected));
  }

  test('the late threshold is a setting', () {
    expect(stateOn('2026-10-28', late: 14), DoseState.due);
    expect(stateOn('2026-11-04', late: 14), DoseState.late);
  });

  group('last allowed age (missed)', () {
    // due 2026-03-20, last allowed 2026-05-20
    test('on the last allowed day it is still late, not missed', () {
      expect(stateOn('2026-05-20', entry: withLimit), DoseState.late);
    });
    test('the day after it is missed', () => expect(stateOn('2026-05-21', entry: withLimit), DoseState.missed));
    test('missed wins over late', () => expect(stateOn('2027-01-01', entry: withLimit), DoseState.missed));
  });

  group('given', () {
    const record = DoseRecord(id: 'd1', scheduleId: 's06', vaccineId: 'v1', dose: 3, givenOn: '2026-10-10', lot: 'L1');
    test('a recorded dose is given, even before its due date', () {
      final d = scheduledDose(nineMonths, birthDate: birth, today: '2026-10-11', records: const [record], lateAfterDays: 7);
      expect(d.state, DoseState.given);
      expect(d.record?.lot, 'L1');
    });
    test('a recorded dose stays given after the last allowed age', () {
      const r = DoseRecord(id: 'd2', scheduleId: 's08', vaccineId: 'v1', dose: 4, givenOn: '2026-06-01');
      expect(stateOn('2027-01-01', entry: withLimit, records: const [r]), DoseState.given);
    });
    test('a record for another entry does not count', () {
      const r = DoseRecord(id: 'd3', scheduleId: 'other', vaccineId: 'v1', dose: 3, givenOn: '2026-10-10');
      expect(stateOn('2026-10-21', records: const [r]), DoseState.due);
    });
  });

  test('scheduleFor groups by age label in schedule order', () {
    const a = ScheduleEntry(id: 'a', vaccineId: 'v1', dose: 1, dueAge: AgeSpan(), ageLabel: 'عند الولادة', order: 0);
    const b = ScheduleEntry(id: 'b', vaccineId: 'v2', dose: 1, dueAge: AgeSpan(months: 2), ageLabel: 'الشهر الثاني', order: 1);
    const c = ScheduleEntry(id: 'c', vaccineId: 'v1', dose: 2, dueAge: AgeSpan(months: 2), ageLabel: 'الشهر الثاني', order: 2);
    final groups = scheduleFor(const [a, b, c], birthDate: birth, today: '2026-10-24', records: const [], lateAfterDays: 7);
    expect(groups.map((g) => g.$1), ['عند الولادة', 'الشهر الثاني']);
    expect(groups[1].$2.map((d) => d.entry.id), ['b', 'c']);
  });

  test('additional vaccine doses: only records without a schedule entry, by dose number', () {
    const records = [
      DoseRecord(id: '1', vaccineId: 'v3', dose: 2, givenOn: '2026-05-01'),
      DoseRecord(id: '2', vaccineId: 'v3', dose: 1, givenOn: '2026-04-01'),
      DoseRecord(id: '3', scheduleId: 's01', vaccineId: 'v3', dose: 1, givenOn: '2026-01-21'),
    ];
    expect(additionalDoses('v3', records).map((r) => r.id), ['2', '1']);
  });
}
