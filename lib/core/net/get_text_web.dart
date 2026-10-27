import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<String> getText(Uri url, {Duration timeout = const Duration(seconds: 5)}) async {
  final res = await web.window.fetch(url.toString().toJS).toDart.timeout(timeout);
  return (await res.text().toDart).toDart;
}
