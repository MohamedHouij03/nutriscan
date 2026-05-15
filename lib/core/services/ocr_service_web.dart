// Web stub for OCR - provides safe no-op behavior on web builds.
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/exceptions.dart';
import '../services/logger_service.dart';

class OcrService {
  OcrService();

  Future<String> extractText(Uint8List imageBytes, {String? imagePath}) async {
    AppLogger.e('Attempted to run OCR on web - not supported');
    throw const OcrException('OCR is not supported on web builds.');
  }

  Future<List<String>> extractTextBlocks(Uint8List imageBytes, {String? imagePath}) async {
    AppLogger.e('Attempted to extract text blocks on web - returning empty');
    return <String>[];
  }

  void dispose() {
    AppLogger.d('Web OCR service disposed');
  }
}

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(service.dispose);
  return service;
});
