// lib/models/allergen_model.dart

/// Represents a detected allergen in an ingredient list.
class AllergenModel {
  final String name;
  final String severity; // 'high', 'medium', 'low'
  final String rawText;  // Original text from ingredient list

  const AllergenModel({
    required this.name,
    required this.severity,
    required this.rawText,
  });

  factory AllergenModel.fromJson(Map<String, dynamic> json) {
    return AllergenModel(
      name: json['name'] as String? ?? '',
      severity: json['severity'] as String? ?? 'medium',
      rawText: json['raw_text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'severity': severity,
    'raw_text': rawText,
  };

  AllergenModel copyWith({
    String? name,
    String? severity,
    String? rawText,
  }) {
    return AllergenModel(
      name: name ?? this.name,
      severity: severity ?? this.severity,
      rawText: rawText ?? this.rawText,
    );
  }

  @override
  String toString() => 'AllergenModel(name: $name, severity: $severity)';
}
