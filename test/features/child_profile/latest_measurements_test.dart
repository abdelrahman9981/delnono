import 'package:delnono/features/child_profile/data/measurements_repository.dart';
import 'package:delnono/features/child_profile/domain/latest_measurements.dart';
import 'package:flutter_test/flutter_test.dart';

const ms = [
  Measurement(id: 'b', measuredOn: '2026-09-15', weightKg: 12.9, lengthCm: 91),
  Measurement(id: 'a', measuredOn: '2026-03-15', weightKg: 11.8, lengthCm: 86.5, headCm: 48),
  Measurement(id: 'c', measuredOn: '2025-09-15', weightKg: 10.6, lengthCm: 81),
];

void main() {
  test('latest value of each measure keeps its own date (FR-003)', () {
    expect(latestOf(ms, Metric.weight), (value: 12.9, date: '2026-09-15'));
    expect(latestOf(ms, Metric.head), (value: 48.0, date: '2026-03-15'));
  });

  test('a measure never recorded has no latest value', () {
    expect(latestOf(const [Measurement(id: 'x', measuredOn: '2026-01-01', weightKg: 4)], Metric.head), isNull);
    expect(latestOf(const [], Metric.weight), isNull);
  });

  test('last measured date', () {
    expect(lastMeasuredOn(ms), '2026-09-15');
    expect(lastMeasuredOn(const []), isNull);
  });

  test('series is oldest first and skips missing values', () {
    expect(seriesOf(ms, Metric.head), [(value: 48.0, date: '2026-03-15')]);
    expect(seriesOf(ms, Metric.weight).map((p) => p.date), ['2025-09-15', '2026-03-15', '2026-09-15']);
  });

  test('birth weight is the first weight point, for weight only', () {
    final s = seriesOf(ms, Metric.weight, birthDate: '2024-03-15', birthWeightKg: 3.2);
    expect(s.first, (value: 3.2, date: '2024-03-15'));
    expect(seriesOf(ms, Metric.length, birthDate: '2024-03-15', birthWeightKg: 3.2).length, 3);
  });
}
