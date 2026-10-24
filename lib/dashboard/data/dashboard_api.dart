import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/callable.dart';
import '../../core/firebase/functions_region.dart';

/// A refused staff action with the server's reason (contracts/callables.md).
class StaffActionRefused implements Exception {
  const StaffActionRefused(this.code, this.reason, [this.details = const {}]);

  final String code;
  final String? reason;
  final Map<String, dynamic> details;
}

/// The 005 callables. Every staff change goes through here (research R3).
abstract interface class DashboardApi {
  Future<Map<String, dynamic>> call(String name, Map<String, Object?> data);
}

class FirebaseDashboardApi implements DashboardApi {
  FirebaseDashboardApi(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<Map<String, dynamic>> call(String name, Map<String, Object?> data) async {
    try {
      final result = await _functions.callFunction<Object?>(name, data);
      final d = result.data;
      return d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
    } on FirebaseFunctionsException catch (e) {
      final details = e.details is Map ? Map<String, dynamic>.from(e.details as Map) : const <String, dynamic>{};
      throw StaffActionRefused(e.code, details['reason'] as String? ?? details['field'] as String?, details);
    }
  }
}

final dashboardApiProvider = Provider<DashboardApi>((ref) => FirebaseDashboardApi(ref.watch(functionsProvider)));
