// Conditional export: use mobile implementation by default, web stub when building for web.
export 'ocr_service_mobile.dart' if (dart.library.html) 'ocr_service_web.dart';
