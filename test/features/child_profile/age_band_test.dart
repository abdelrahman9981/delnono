import 'package:delnono/features/child_profile/data/follow_up_repository.dart';
import 'package:delnono/features/child_profile/domain/age_band.dart';
import 'package:flutter_test/flutter_test.dart';

const bands = [
  FollowUpBand(fromMonths: 0, toMonths: 2, title: 'a', items: []),
  FollowUpBand(fromMonths: 6, toMonths: 9, title: 'b', items: []),
  FollowUpBand(fromMonths: 9, toMonths: 12, title: 'c', items: []),
  FollowUpBand(fromMonths: 36, toMonths: 48, title: 'd', items: []),
];

void main() {
  test('band boundaries: from inclusive, to exclusive', () {
    expect(bandFor(bands, 0, 48)?.title, 'a');
    expect(bandFor(bands, 8, 48)?.title, 'b');
    expect(bandFor(bands, 9, 48)?.title, 'c');
    expect(bandFor(bands, 47, 48)?.title, 'd');
  });

  test('no band for an uncovered age', () => expect(bandFor(bands, 3, 48), isNull));

  test('nothing from the age limit on (FR-018)', () {
    expect(bandFor(bands, 48, 48), isNull);
    expect(bandFor(bands, 40, 36), isNull);
  });
}
