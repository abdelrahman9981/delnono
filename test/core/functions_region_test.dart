import 'dart:io';

import 'package:delnono/core/firebase/functions_region.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the app calls functions in the region they are deployed to (BRD D-53)', () {
    final server = File('functions/src/lib/region.ts').readAsStringSync();
    expect(RegExp(r'REGION = "([a-z0-9-]+)"').firstMatch(server)?.group(1), functionsRegion);
    expect(functionsRegion, 'me-central1', reason: "the real project's Firestore location");
  });
}
