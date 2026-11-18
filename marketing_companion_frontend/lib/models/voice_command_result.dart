
class VoiceCommandResult {
  final String intent;
  final String? productQuery;
  final VoiceCommandUpdates? updates;
  final double confidence;
  final String responseLanguage;
  final bool needsClarification;
  final String? clarificationQuestion;

  const VoiceCommandResult({
    required this.intent,
    this.productQuery,
    this.updates,
    required this.confidence,
    required this.responseLanguage,
    required this.needsClarification,
    this.clarificationQuestion,
  });

  factory VoiceCommandResult.fromJson(Map<String, dynamic> json) {
    return VoiceCommandResult(
      intent: json['intent']?.toString() ?? 'unknown',
      productQuery: json['product_query']?.toString(),
      updates: json['updates'] is Map
          ? VoiceCommandUpdates.fromJson(
              Map<String, dynamic>.from(json['updates']),
            )
          : null,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      responseLanguage:
          json['response_language']?.toString() ?? 'unknown',
      needsClarification: json['needs_clarification'] == true,
      clarificationQuestion:
          json['clarification_question']?.toString(),
    );
  }
}

class VoiceCommandUpdates {
  final String? title;
  final String? description;
  final String? category;
  final double? price;

  const VoiceCommandUpdates({
    this.title,
    this.description,
    this.category,
    this.price,
  });

  factory VoiceCommandUpdates.fromJson(Map<String, dynamic> json) {
    return VoiceCommandUpdates(
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      category: json['category']?.toString(),
      price: (json['price'] as num?)?.toDouble(),
    );
  }
}
