import 'child_age.dart';

/// The family package as shown on the profile (FR-020). Owned by feature 006; read only here.
class PackageStatus {
  const PackageStatus({required this.active, required this.endsOn, required this.monthsLeft});

  final bool active;

  /// `YYYY-MM-DD`.
  final String endsOn;

  /// Whole months from today to the end date (0 when ended).
  final int monthsLeft;
}

/// The package to show: an active one covering [today] first, otherwise the most recently ended
/// one; null without packages. [packages] are `(active, startsOn, endsOn)`.
PackageStatus? packageStatus(List<({bool active, String startsOn, String endsOn})> packages, String today) {
  ({bool active, String startsOn, String endsOn})? current;
  ({bool active, String startsOn, String endsOn})? ended;
  for (final p in packages) {
    final covers = compareDates(p.startsOn, today) <= 0 && compareDates(today, p.endsOn) <= 0;
    if (p.active && covers) {
      if (current == null || compareDates(p.endsOn, current.endsOn) > 0) current = p;
    } else if (compareDates(p.endsOn, today) < 0 || !p.active) {
      if (ended == null || compareDates(p.endsOn, ended.endsOn) > 0) ended = p;
    }
  }
  if (current != null) {
    return PackageStatus(active: true, endsOn: current.endsOn, monthsLeft: ageInMonths(today, current.endsOn));
  }
  if (ended != null) return PackageStatus(active: false, endsOn: ended.endsOn, monthsLeft: 0);
  return null;
}
