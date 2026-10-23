import 'package:delnono/core/phone/egypt_phone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeEgyptMobile', () {
    const expected = '+201012345678';

    for (final input in [
      '01012345678',
      '1012345678',
      '+201012345678',
      '00201012345678',
      '201012345678',
      '010 1234 5678',
      '010-1234-5678',
      '+20 (10) 1234 5678',
      '٠١٠١٢٣٤٥٦٧٨',
      '۰۱۰۱۲۳۴۵۶۷۸',
    ]) {
      test('accepts "$input"', () => expect(normalizeEgyptMobile(input), expected));
    }

    test('accepts every mobile prefix 10, 11, 12, 15', () {
      for (final prefix in ['010', '011', '012', '015']) {
        expect(normalizeEgyptMobile('${prefix}12345678'), '+2${prefix}12345678');
      }
    });

    for (final input in [
      '',
      '0101234567', // too short
      '010123456789', // too long
      '01312345678', // 13 is not a mobile prefix
      '0221234567', // Cairo landline
      '+971501234567', // another country
      '+44 20 7946 0958',
      '01012345678a',
      '++201012345678',
      '010+12345678',
    ]) {
      test('rejects "$input"', () => expect(normalizeEgyptMobile(input), isNull));
    }
  });

  test('isValidEgyptMobile only accepts E.164', () {
    expect(isValidEgyptMobile('+201512345678'), isTrue);
    expect(isValidEgyptMobile('01512345678'), isFalse);
    expect(isValidEgyptMobile('+201412345678'), isFalse);
  });
}
