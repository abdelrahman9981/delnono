import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Must match `REGION` in functions/src/lib/region.ts (research R8 decides the final value).
const functionsRegion = 'us-central1';

final functionsProvider =
    Provider<FirebaseFunctions>((ref) => FirebaseFunctions.instanceFor(region: functionsRegion));
