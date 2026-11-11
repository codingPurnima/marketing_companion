
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  Future<bool> initializeSpeech({
    required Function(String) onStatus,
    required Function(String) onError,
  }) async {
    try {
      return await _speech.initialize(
        onStatus: onStatus,
        onError: (error) => onError(error.errorMsg),
      );
    } catch (e) {
      debugPrint('Speech initialization error: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
  }) async {
    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      listenFor: const Duration(minutes: 1),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> initializeTts() async {
    try {
      await _tts.setLanguage('en-IN');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      debugPrint('TTS initialized successfully');
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  Future<void> speakCatalogSummary(Map<String, dynamic> draft) async {
    final title = draft['title']?.toString() ?? '';
    final description = draft['description']?.toString() ?? '';
    final category = draft['category']?.toString() ?? 'other';
    final price = draft['price_inr']?.toString();

    final summary = '''
Your catalog draft is ready.
Product title: $title.
Category: $category.
${price != null && price.isNotEmpty ? 'Price: $price rupees.' : 'No price was provided.'}
Description: $description.
Please review these details before saving.
''';

    try {
      debugPrint('TTS: Starting speech');
      final result = await _tts.speak(summary);
      debugPrint('TTS speak result: $result');
    } catch (e) {
      debugPrint('TTS playback error: $e');
    }
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  Future<void> speak(String text) async {
  try {
    await _tts.speak(text);
  } catch (e) {
    debugPrint('TTS playback error: $e');
  }
}
}
