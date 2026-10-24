import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Files the app keeps for the signed-in guardian (the selected child).
/// They live under the app support folder, which the OS does not purge, and are deleted on sign-out
/// with the Firestore cache (constitution Principle I).
abstract final class PrivateFiles {
  static Future<Directory> _root() async => Directory('${(await getApplicationSupportDirectory()).path}/private');

  /// The folder [name], created if needed.
  static Future<Directory> dir(String name) async {
    final d = Directory('${(await _root()).path}/$name');
    await d.create(recursive: true);
    return d;
  }

  /// Deletes every private file. Never throws: sign-out must go on.
  static Future<void> clear() async {
    try {
      final root = await _root();
      if (await root.exists()) await root.delete(recursive: true);
    } catch (_) {}
  }
}
