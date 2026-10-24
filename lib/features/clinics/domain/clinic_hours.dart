/// An open range of hours on a weekday: from `from`:00 up to `to`:00.
class HourRange {
  const HourRange(this.from, this.to);

  final int from;
  final int to;
}

/// `workingHours` as stored on a clinic: ISO weekday ("1"–"7") → ranges. Missing = closed.
Map<int, List<HourRange>>? parseWorkingHours(Object? raw) {
  if (raw is! Map) return null;
  return {
    for (final e in raw.entries)
      int.parse(e.key.toString()): [
        for (final r in (e.value as List? ?? const []).cast<Map>())
          HourRange((r['from'] as num).toInt(), (r['to'] as num).toInt()),
      ],
  };
}
