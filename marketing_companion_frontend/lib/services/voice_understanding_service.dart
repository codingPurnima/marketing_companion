
import 'api_service.dart';
import '../models/voice_command_result.dart';

class VoiceUnderstandingService {
  final ApiService apiService;

  VoiceUnderstandingService({
    required this.apiService,
  });

  Future<VoiceCommandResult> understandCommand({
    required String transcript,
    String languageHint = 'auto',
  }) async {
    final cleanedTranscript = transcript.trim();

    if (cleanedTranscript.isEmpty) {
      throw Exception('Please provide a voice command.');
    }

    final response = await apiService.request(
      '/api/v1/voice/understand',
      method: 'POST',
      body: {
        'transcript': cleanedTranscript,
        'language_hint': languageHint,
      },
    );

    if (response is! Map) {
      throw Exception(
        'Invalid response received from voice understanding service.',
      );
    }

    return VoiceCommandResult.fromJson(
      Map<String, dynamic>.from(response),
    );
  }
}
