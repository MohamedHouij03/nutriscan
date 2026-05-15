// lib/models/additive_model.dart

/// Represents a detected harmful additive (E-number).
class AdditiveModel {
  final String code;     // e.g. "E102"
  final String name;     // e.g. "Tartrazine"
  final String concern;  // e.g. "hyperactivity in children"
  final String rawText;  // Original text from ingredient list

  const AdditiveModel({
    required this.code,
    required this.name,
    required this.concern,
    required this.rawText,
  });

  factory AdditiveModel.fromJson(Map<String, dynamic> json) {
    return AdditiveModel(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      concern: json['concern'] as String? ?? '',
      rawText: json['raw_text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'concern': concern,
    'raw_text': rawText,
  };

  AdditiveModel copyWith({
    String? code,
    String? name,
    String? concern,
    String? rawText,
  }) {
    return AdditiveModel(
      code: code ?? this.code,
      name: name ?? this.name,
      concern: concern ?? this.concern,
      rawText: rawText ?? this.rawText,
    );
  }

  @override
  String toString() => 'AdditiveModel(code: $code, name: $name)';
}
