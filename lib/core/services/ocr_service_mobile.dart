// Mobile implementation using Google ML Kit
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/exceptions.dart';
import '../services/logger_service.dart';

class OcrService {
  final TextRecognizer _textRecognizer;

  OcrService()
      : _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> extractText(Uint8List imageBytes, {String? imagePath}) async {
    AppLogger.i('Starting OCR on image: ${imagePath ?? '<bytes>'}');
    try {
      final inputImage = imagePath != null
          ? InputImage.fromFilePath(imagePath)
          : await _buildInputImageFromBytes(imageBytes);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final text = recognizedText.text;
      AppLogger.i('OCR extracted ${text.length} characters');
      if (text.trim().isEmpty)
        throw const OcrException('No text found in image.');
      return _cleanText(text);
    } on OcrException {
      rethrow;
    } catch (e, st) {
      AppLogger.e('OCR processing error', e, st);
      throw OcrException('OCR processing failed: $e');
    }
  }

  Future<List<String>> extractTextBlocks(Uint8List imageBytes,
      {String? imagePath}) async {
    try {
      final inputImage = imagePath != null
          ? InputImage.fromFilePath(imagePath)
          : await _buildInputImageFromBytes(imageBytes);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final lines = <String>[];
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final lineText = line.elements.map((e) => e.text).join(' ');
          if (lineText.trim().isNotEmpty) lines.add(lineText.trim());
        }
      }
      return lines;
    } catch (e) {
      AppLogger.e('OCR block extraction error', e);
      return [];
    }
  }

  Future<InputImage> _buildInputImageFromBytes(Uint8List bytes) async {
    final completer = Completer<ui.Image>();
    try {
      ui.decodeImageFromList(bytes, (ui.Image image) {
        if (!completer.isCompleted) completer.complete(image);
      });
    } catch (e, st) {
      if (!completer.isCompleted) completer.completeError(e, st);
    }
    final ui.Image decoded = await completer.future;
    final metadata = InputImageMetadata(
      size: ui.Size(decoded.width.toDouble(), decoded.height.toDouble()),
      rotation: InputImageRotation.rotation0deg,
      format: InputImageFormat.bgra8888,
      bytesPerRow: decoded.width * 4,
    );
    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  String _cleanText(String raw) {
    return raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\x20-\x7E\n]'), '')
        .trim();
  }

  void dispose() {
    _textRecognizer.close();
    AppLogger.d('OCR service disposed');
  }
}

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(service.dispose);
  return service;
});
