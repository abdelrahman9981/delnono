import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

extension LoggedCallable on FirebaseFunctions {
  /// Calls the function [name]. Screens show only a short Arabic message, so in debug builds the
  /// error's code and message are also printed to the console.
  Future<HttpsCallableResult<T>> callFunction<T>(String name, [Object? data]) async {
    try {
      return await httpsCallable(name).call<T>(data);
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        debugPrint('Cloud Function $name failed: ${e.code}: ${e.message}${e.details == null ? '' : ' ${e.details}'}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint('Cloud Function $name failed: $e');
      rethrow;
    }
  }
}
