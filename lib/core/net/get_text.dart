/// `GET` [url] and return the body: dart:io on phones, the browser's fetch on the web.
library;

export 'get_text_io.dart' if (dart.library.js_interop) 'get_text_web.dart';
