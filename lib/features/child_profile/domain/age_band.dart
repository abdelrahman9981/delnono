import '../data/follow_up_repository.dart';

/// The follow-up band for a child aged [ageMonths], or null from [maxAgeMonths] on or when no band
/// covers the age (FR-016, FR-018).
FollowUpBand? bandFor(List<FollowUpBand> bands, int ageMonths, int maxAgeMonths) {
  if (ageMonths >= maxAgeMonths) return null;
  for (final b in bands) {
    if (b.fromMonths <= ageMonths && ageMonths < b.toMonths) return b;
  }
  return null;
}
