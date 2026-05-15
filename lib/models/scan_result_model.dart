// lib/models/scan_result_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'allergen_model.dart';
import 'additive_model.dart';

/// Complete scan result stored in Firestore and returned by AI.
class ScanResultModel {
  final String id;
  final String userId;
  final String extractedText;
  final List<AllergenModel> allergens;
  final List<AdditiveModel> additives;
  final double confidence;
  final DateTime timestamp;
  final String? imageUrl;   // Optional Firebase Storage URL

  const ScanResultModel({
    required this.id,
    required this.userId,
    required this.extractedText,
    required this.allergens,
    required this.additives,
    required this.confidence,
    required this.timestamp,
    this.imageUrl,
  });

  /// Whether any allergens or additives were found.
  bool get hasIssues => allergens.isNotEmpty || additives.isNotEmpty;

  /// Total number of issues detected.
  int get issueCount => allergens.length + additives.length;

  /// Highest allergen severity found.
  String get overallSeverity {
    if (allergens.any((a) => a.severity == 'high')) return 'high';
    if (allergens.any((a) => a.severity == 'medium')) return 'medium';
    if (allergens.isNotEmpty || additives.isNotEmpty) return 'low';
    return 'safe';
  }

  factory ScanResultModel.fromJson(Map<String, dynamic> json, String id) {
    return ScanResultModel(
      id: id,
      userId: json['user_id'] as String? ?? '',
      extractedText: json['extracted_text'] as String? ?? '',
      allergens: (json['allergens'] as List<dynamic>? ?? [])
          .map((e) => AllergenModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      additives: (json['additives'] as List<dynamic>? ?? [])
          .map((e) => AdditiveModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'user_id': userId,
    'extracted_text': extractedText,
    'allergens': allergens.map((a) => a.toJson()).toList(),
    'additives': additives.map((a) => a.toJson()).toList(),
    'confidence': confidence,
    'timestamp': Timestamp.fromDate(timestamp),
    'image_url': imageUrl,
  };

  /// For local Hive cache (JSON-safe, no Timestamp).
  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'extracted_text': extractedText,
    'allergens': allergens.map((a) => a.toJson()).toList(),
    'additives': additives.map((a) => a.toJson()).toList(),
    'confidence': confidence,
    'timestamp': timestamp.toIso8601String(),
    'image_url': imageUrl,
  };

  ScanResultModel copyWith({
    String? id,
    String? userId,
    String? extractedText,
    List<AllergenModel>? allergens,
    List<AdditiveModel>? additives,
    double? confidence,
    DateTime? timestamp,
    String? imageUrl,
  }) {
    return ScanResultModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      extractedText: extractedText ?? this.extractedText,
      allergens: allergens ?? this.allergens,
      additives: additives ?? this.additives,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() =>
      'ScanResultModel(id: $id, allergens: ${allergens.length}, additives: ${additives.length})';
}

/// Lightweight model for NER API response parsing.
class NerResponseModel {
  final List<AllergenModel> allergens;
  final List<AdditiveModel> additives;
  final double confidence;

  const NerResponseModel({
    required this.allergens,
    required this.additives,
    required this.confidence,
  });

  factory NerResponseModel.fromJson(Map<String, dynamic> json) {
    return NerResponseModel(
      allergens: (json['allergens'] as List<dynamic>? ?? [])
          .map((e) => AllergenModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      additives: (json['additives'] as List<dynamic>? ?? [])
          .map((e) => AdditiveModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
