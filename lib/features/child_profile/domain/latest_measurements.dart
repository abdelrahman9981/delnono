import '../data/measurements_repository.dart';

enum Metric { weight, length, head }

/// A value with the date it was measured.
typedef Dated = ({double value, String date});

double? valueOf(Measurement m, Metric metric) => switch (metric) {
  Metric.weight => m.weightKg,
  Metric.length => m.lengthCm,
  Metric.head => m.headCm,
};

/// The latest recorded value of [metric], each with its own date (FR-003). [measurements] in any order.
Dated? latestOf(List<Measurement> measurements, Metric metric) {
  Dated? best;
  for (final m in measurements) {
    final v = valueOf(m, metric);
    if (v == null) continue;
    if (best == null || m.measuredOn.compareTo(best.date) > 0) best = (value: v, date: m.measuredOn);
  }
  return best;
}

/// The date of the most recent measurement, or null.
String? lastMeasuredOn(List<Measurement> measurements) {
  String? last;
  for (final m in measurements) {
    if (last == null || m.measuredOn.compareTo(last) > 0) last = m.measuredOn;
  }
  return last;
}

/// The chart's points for [metric], oldest first: the birth weight (entered by the guardian in 001)
/// as the first weight point when no measurement exists on the birth date, then every recorded value.
List<Dated> seriesOf(List<Measurement> measurements, Metric metric, {String? birthDate, double? birthWeightKg}) {
  final points = <Dated>[
    for (final m in measurements)
      if (valueOf(m, metric) case final v?) (value: v, date: m.measuredOn),
  ]..sort((a, b) => a.date.compareTo(b.date));
  if (metric == Metric.weight &&
      birthWeightKg != null &&
      birthDate != null &&
      points.every((p) => p.date != birthDate)) {
    points.insert(0, (value: birthWeightKg, date: birthDate));
  }
  return points;
}
