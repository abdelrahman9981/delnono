import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/functions_region.dart';

/// `reverifyGuardian`: the date matched no linked child; [remaining] tries are left.
class ReverifyWrongBirthDate implements Exception {
  const ReverifyWrongBirthDate(this.remaining);

  final int remaining;
}

/// `reverifyGuardian`: locked after too many wrong dates (FR-010b).
class ReverifyLocked implements Exception {
  const ReverifyLocked();
}

/// Session callables for the re-check after inactivity (FR-010a; contracts/callables.md).
abstract interface class SessionApi {
  /// Returns true when a birth-date re-check is required before child data.
  Future<bool> touchSession();

  /// Throws [ReverifyWrongBirthDate] or [ReverifyLocked].
  Future<void> reverifyGuardian(String birthDate);
}

class FirebaseSessionApi implements SessionApi {
  FirebaseSessionApi(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<bool> touchSession() async {
    final result = await _functions.httpsCallable('touchSession').call<Map<String, dynamic>>({});
    return result.data['reverifyRequired'] == true;
  }

  @override
  Future<void> reverifyGuardian(String birthDate) async {
    try {
      await _functions.httpsCallable('reverifyGuardian').call<Object?>({'birthDate': birthDate});
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'permission-denied') {
        final details = e.details;
        final remaining = details is Map ? details['remaining'] : null;
        throw ReverifyWrongBirthDate(remaining is num ? remaining.toInt() : 0);
      }
      if (e.code == 'resource-exhausted') throw const ReverifyLocked();
      rethrow;
    }
  }
}

final sessionApiProvider = Provider<SessionApi>((ref) => FirebaseSessionApi(ref.watch(functionsProvider)));
