import 'dart:convert';
import 'dart:io';

Future<String> getText(Uri url, {Duration timeout = const Duration(seconds: 5)}) async {
  final client = HttpClient();
  try {
    final res = await (await client.getUrl(url)).close().timeout(timeout);
    return await res.transform(utf8.decoder).join();
  } finally {
    client.close();
  }
}
