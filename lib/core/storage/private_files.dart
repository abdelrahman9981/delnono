import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// The web has no files: private values live in browser storage under this prefix.
  static const webPrefix = 'private.';

  /// Deletes every private file. Never throws: sign-out must go on.
  static Future<void> clear() async {
    if (kIsWeb) {
      try {
        final prefs = SharedPreferencesAsync();
        for (final key in await prefs.getKeys()) {
          if (key.startsWith(webPrefix)) await prefs.remove(key);
        }
      } catch (_) {}
      return;
    }
    try {
      final root = await _root();
      if (await root.exists()) await root.delete(recursive: true);
    } catch (_) {}
  }
}
