import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/exceptions.dart';
import '../services/logger_service.dart';

class OcrService {
  final Dio _dio;

  OcrService({required String apiKey})
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://api.mistral.ai',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ));

  /// Extract text from an image using Mistral AI OCR.
  Future<String> extractText(
    Uint8List imageBytes, {
    String? imagePath,
  }) async {
    AppLogger.i('Starting Mistral OCR on image: ${imagePath ?? '<bytes>'}');

    try {
      final base64Image = base64Encode(imageBytes);

      final response = await _dio.post(
        '/v1/ocr',
        data: {
          'model': 'mistral-ocr-latest',
          'document': {
            'type': 'image_url',
            'image_url': 'data:image/jpeg;base64,$base64Image',
          },
        },
      );

      final pages = response.data['pages'] as List<dynamic>?;

      if (pages == null || pages.isEmpty) {
        throw const OcrException('No pages returned from OCR.');
      }

      final text = pages[0]['markdown'] as String? ?? '';

      AppLogger.i('Mistral OCR extracted ${text.length} characters');

      if (text.trim().isEmpty) {
        throw const OcrException('No text found in image.');
      }

      return _cleanText(text);
    } on DioException catch (e) {
      AppLogger.e('Mistral OCR API error', e);

      if (e.response?.data != null) {
        AppLogger.e('Error response body: ${e.response?.data}');
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const OcrException('OCR request timed out.');
      }

      throw OcrException(
        'OCR API failed: ${e.response?.statusCode} ${e.message}',
      );
    } catch (e, st) {
      AppLogger.e('OCR processing error', e, st);
      throw OcrException('OCR processing failed: $e');
    }
  }

  /// Extract text as line-by-line blocks.
  Future<List<String>> extractTextBlocks(
    Uint8List imageBytes, {
    String? imagePath,
  }) async {
    try {
      final fullText = await extractText(imageBytes, imagePath: imagePath);

      return fullText
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
    } catch (e) {
      AppLogger.e('OCR block extraction error', e);
      return [];
    }
  }

  String _cleanText(String raw) {
    return raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\x20-\x7E\n]'), '')
        .trim();
  }

  void dispose() {
    _dio.close();
    AppLogger.d('Mistral OCR service disposed');
  }
}

/// Riverpod provider
final ocrServiceProvider = Provider<OcrService>((ref) {
  const apiKey = String.fromEnvironment('MISTRAL_API_KEY');

  return OcrService(apiKey: apiKey);
});
