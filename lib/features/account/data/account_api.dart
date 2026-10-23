import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/functions_region.dart';

/// Account callables (contracts/callables.md).
abstract interface class AccountApi {
  /// Copies the account's new number to the guardian and children (FR-025, FR-026).
  Future<void> syncPhoneNumber();

  /// Deletes the app account; the clinic keeps the children's records (FR-027 to FR-030).
  Future<void> deleteAccount();
}

class FirebaseAccountApi implements AccountApi {
  FirebaseAccountApi(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<void> syncPhoneNumber() => _functions.httpsCallable('syncPhoneNumber').call<Object?>({});

  @override
  Future<void> deleteAccount() => _functions.httpsCallable('deleteAccount').call<Object?>({'confirm': true});
}

final accountApiProvider = Provider<AccountApi>((ref) => FirebaseAccountApi(ref.watch(functionsProvider)));
