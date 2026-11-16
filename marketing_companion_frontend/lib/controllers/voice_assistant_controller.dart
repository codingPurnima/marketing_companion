
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/speech_service.dart';

class VoiceAssistantController extends ChangeNotifier {
  final SpeechService speechService = SpeechService();

  bool speechAvailable = false;
  bool isListening = false;
  bool initialized = false;

  String speechMessage = '';

  Future<void>? _initializationFuture;

  Future<void> initialize() {
    return _initializationFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    final available = await speechService.initializeSpeech(
      onStatus: (status) {
        isListening = status == 'listening';

        if (status == 'done' || status == 'notListening') {
          isListening = false;
        }

        notifyListeners();
      },
      onError: (error) {
        isListening = false;
        speechMessage = error;
        notifyListeners();
      },
    );

    speechAvailable = available;

    speechMessage = available
        ? 'Voice input is ready.'
        : 'Speech recognition is unavailable on this device.';

    await speechService.initializeTts();

    initialized = true;
    notifyListeners();
  }

  Future<void> startListening({
    required Function(String) onResult,
  }) async {
    if (!speechAvailable || isListening) return;

    speechMessage = 'Listening...';
    notifyListeners();

    await speechService.startListening(
      onResult: onResult,
    );
  }

  Future<void> stopListening() async {
    await speechService.stopListening();

    isListening = false;
    speechMessage = 'Voice input captured. Review the transcription.';

    notifyListeners();
  }

  Future<void> speak(String text) {
    return speechService.speak(text);
  }

  Future<void> speakCatalogSummary(
    Map<String, dynamic> draft,
  ) {
    return speechService.speakCatalogSummary(draft);
  }

  Future<void> stopSpeaking() {
    return speechService.stopSpeaking();
  }

  @override
  void dispose() {
    unawaited(speechService.stopListening());
    unawaited(speechService.stopSpeaking());
    super.dispose();
  }
}
