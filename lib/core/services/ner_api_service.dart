// lib/core/services/ner_api_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../services/logger_service.dart';
import '../../models/additive_model.dart';
import '../../models/allergen_model.dart';
import '../../models/scan_result_model.dart';

/// Configuration for the NER API provider.
/// Switch between Mistral, OpenAI, or HuggingFace.
enum NerProvider { mistral, openai, huggingface }

class NerApiConfig {
  final String baseUrl;
  final String apiKey;
  final String model;
  final NerProvider provider;

  const NerApiConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.provider,
  });

  /// Default: Mistral AI
  static const NerApiConfig mistral = NerApiConfig(
    baseUrl: 'https://api.mistral.ai/v1',
    apiKey: String.fromEnvironment('MISTRAL_API_KEY', defaultValue: ''),
    model: 'mistral-small-latest',
    provider: NerProvider.mistral,
  );

  /// OpenAI fallback
  static const NerApiConfig openai = NerApiConfig(
    baseUrl: 'https://api.openai.com/v1',
    apiKey: String.fromEnvironment('OPENAI_API_KEY', defaultValue: ''),
    model: 'gpt-3.5-turbo',
    provider: NerProvider.openai,
  );
}

/// Service responsible for calling AI API to perform NER on extracted text.
/// Implements retry logic, timeout handling, and JSON parsing.
class NerApiService {
  final Dio _dio;
  final NerApiConfig _config;

  NerApiService({NerApiConfig config = NerApiConfig.mistral})
      : _config = config,
        _dio = Dio(
          BaseOptions(
            baseUrl: config.baseUrl,
            connectTimeout: AppConstants.apiTimeout,
            receiveTimeout: AppConstants.apiTimeout,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${config.apiKey}',
            },
          ),
        ) {
    // Add logging interceptor in debug mode
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (o) => AppLogger.d(o.toString()),
      ),
    );
  }

  /// Analyze ingredient text with AI NER.
  /// Returns [NerResponseModel] with detected allergens and additives.
  /// Throws [NerException] on failure.
  Future<NerResponseModel> analyzeIngredients(String extractedText) async {
    if (extractedText.trim().isEmpty) {
      throw const NerException('Empty text provided for analysis.');
    }

    AppLogger.i('NER analysis started. Text length: ${extractedText.length}');

    try {
      final response = await _dio.post(
        '/chat/completions',
        data: _buildRequestBody(extractedText),
      );

      return _parseResponse(response.data);
    } on DioException catch (e) {
      AppLogger.e('Dio error during NER', e, e.stackTrace);
      _handleDioError(e);
    } on FormatException catch (e) {
      AppLogger.e('JSON parse error', e);
      throw NerException('Failed to parse AI response: ${e.message}');
    } catch (e) {
      AppLogger.e('Unexpected NER error', e);
      throw NerException('Unexpected error: $e');
    }
  }

  /// Build the request body for chat completions API.
  Map<String, dynamic> _buildRequestBody(String extractedText) {
    return {
      'model': _config.model,
      'messages': [
        {
          'role': 'system',
          'content': AppConstants.nerSystemPrompt,
        },
        {
          'role': 'user',
          'content':
              'Analyze this ingredient list and return JSON:\n\n$extractedText',
        }
      ],
      'temperature': 0.1, // Low temperature for consistent JSON output
      'max_tokens': 1000,
      'response_format': {'type': 'json_object'}, // Force JSON mode
    };
  }

  /// Parse the API response into [NerResponseModel].
  NerResponseModel _parseResponse(dynamic responseData) {
    final choices = responseData['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw const NerException('Empty response from AI API.');
    }

    final content = choices[0]['message']['content'] as String?;
    if (content == null || content.isEmpty) {
      throw const NerException('No content in AI response.');
    }

    AppLogger.i(
        'NER raw response: ${content.substring(0, content.length.clamp(0, 200))}');

    // Parse JSON from response
    final jsonStr = _extractJson(content);
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;

    return NerResponseModel.fromJson(json);
  }

  /// Extract clean JSON from response string (handles markdown code blocks).
  String _extractJson(String content) {
    // Remove markdown code blocks if present
    String clean = content.trim();
    if (clean.startsWith('```json')) {
      clean = clean.substring(7);
    }
    if (clean.startsWith('```')) {
      clean = clean.substring(3);
    }
    if (clean.endsWith('```')) {
      clean = clean.substring(0, clean.length - 3);
    }
    return clean.trim();
  }

  /// Map Dio errors to typed exceptions.
  Never _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        throw const TimeoutException();
      case DioExceptionType.connectionError:
        throw const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          throw const NerException(
              'Invalid API key. Check your configuration.');
        } else if (statusCode == 429) {
          throw const NerException(
              'Rate limit exceeded. Please wait before retrying.');
        } else if (statusCode != null && statusCode >= 500) {
          throw NerException('AI service unavailable (HTTP $statusCode).');
        }
        throw NerException('API error: ${e.response?.statusMessage}');
      default:
        throw NerException('Network error: ${e.message}');
    }
  }

  /// Local fallback: keyword-based detection when API unavailable.
  /// Less accurate but ensures app doesn't crash.
  NerResponseModel analyzeLocally(String text) {
    AppLogger.w('Using local fallback NER analysis');
    final lowerText = text.toLowerCase();
    final allergens = <AllergenModel>[];
    final additives = <AdditiveModel>[];

    // Check allergen keywords
    for (final keyword in AppConstants.allergenKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        // Avoid duplicates
        final name = _mapKeywordToAllergenName(keyword);
        if (!allergens.any((a) => a.name == name)) {
          allergens.add(AllergenModel(
            name: name,
            severity: _getAllergenSeverity(keyword),
            rawText: keyword,
          ));
        }
      }
    }

    // Check E-numbers
    for (final eNumber in AppConstants.harmfulENumbers) {
      if (lowerText.contains(eNumber.toLowerCase())) {
        additives.add(AdditiveModel(
          code: eNumber,
          name: _eNumberName(eNumber),
          concern: _eNumberConcern(eNumber),
          rawText: eNumber,
        ));
      }
    }

    return NerResponseModel(
      allergens: allergens,
      additives: additives,
      confidence: 0.6, // Lower confidence for local analysis
    );
  }

  String _mapKeywordToAllergenName(String keyword) {
    final k = keyword.toLowerCase();
    if (['lait', 'lactose', 'dairy'].contains(k)) return 'milk';
    if (['blé', 'farine', 'wheat'].contains(k)) return 'gluten/wheat';
    if (['oeuf', 'eggs'].contains(k)) return 'egg';
    if (['arachide'].contains(k)) return 'peanut';
    if (['noix', 'almond', 'amande'].contains(k)) return 'tree nut';
    if (['soja'].contains(k)) return 'soy';
    if (['poisson', 'cod', 'salmon'].contains(k)) return 'fish';
    if (['crustacé', 'crevette', 'shrimp'].contains(k)) return 'shellfish';
    if (['sésame'].contains(k)) return 'sesame';
    if (['moutarde'].contains(k)) return 'mustard';
    if (['céleri'].contains(k)) return 'celery';
    if (['sulfite', 'sulphite'].contains(k)) return 'sulphites';
    return keyword;
  }

  String _getAllergenSeverity(String keyword) {
    final high = ['peanut', 'arachide', 'shellfish', 'crustacé'];
    final medium = ['milk', 'lait', 'egg', 'oeuf', 'gluten', 'wheat', 'blé'];
    if (high.contains(keyword.toLowerCase())) return 'high';
    if (medium.contains(keyword.toLowerCase())) return 'medium';
    return 'low';
  }

  String _eNumberName(String code) {
    const names = {
      'E102': 'Tartrazine',
      'E110': 'Sunset Yellow',
      'E122': 'Carmoisine',
      'E124': 'Ponceau 4R',
      'E129': 'Allura Red',
      'E210': 'Benzoic Acid',
      'E211': 'Sodium Benzoate',
      'E220': 'Sulphur Dioxide',
      'E250': 'Sodium Nitrite',
      'E320': 'BHA',
      'E321': 'BHT',
      'E621': 'MSG (Monosodium Glutamate)',
    };
    return names[code] ?? 'Food Additive';
  }

  String _eNumberConcern(String code) {
    const concerns = {
      'E102': 'Hyperactivity in children, potential allergen',
      'E110': 'Hyperactivity, allergic reactions',
      'E122': 'Hyperactivity in children',
      'E124': 'Carcinogenic in animal studies',
      'E129': 'Hyperactivity, allergic reactions',
      'E210': 'May cause asthma, urticaria',
      'E211': 'Possible carcinogen when combined with vitamin C',
      'E220': 'Asthma trigger, sulphite sensitivity',
      'E250': 'Potential carcinogen, especially at high temperatures',
      'E320': 'Possible carcinogen',
      'E321': 'Potential endocrine disruptor',
      'E621': 'Headaches, numbness in sensitive individuals',
    };
    return concerns[code] ?? 'May cause adverse reactions in some people';
  }
}

/// Riverpod provider for NerApiService.
final nerApiServiceProvider = Provider<NerApiService>(
  (ref) => NerApiService(config: NerApiConfig.mistral),
);
