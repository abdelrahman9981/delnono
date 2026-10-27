import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// me-central1 (Doha), with Firestore on dr-elnono-clinic (BRD D-53). Must match `REGION` in
/// functions/src/lib/region.ts (test/core/functions_region_test.dart).
const functionsRegion = 'me-central1';

final functionsProvider =
    Provider<FirebaseFunctions>((ref) => FirebaseFunctions.instanceFor(region: functionsRegion));
