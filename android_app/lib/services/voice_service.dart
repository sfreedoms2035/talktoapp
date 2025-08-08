import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          // Handle error
          print('Speech recognition error: $error');
        },
        onStatus: (status) {
          // Handle status changes
          print('Speech recognition status: $status');
        },
      );
    } catch (e) {
      print('Error initializing speech recognition: $e');
      _isInitialized = false;
    }
  }

  Future<String> listen() async {
    if (!_isInitialized) {
      throw Exception('Speech recognition not initialized');
    }

    final completer = Completer<String>();
    String recognizedText = '';

    try {
      _speech.listen(
        onResult: (result) {
          recognizedText = result.recognizedWords;
          if (result.finalResult) {
            _speech.stop();
            completer.complete(recognizedText);
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      );
    } catch (e) {
      completer.completeError(e);
    }

    // Set a timeout
    Future.delayed(const Duration(seconds: 15), () {
      if (!completer.isCompleted) {
        _speech.stop();
        completer.complete('');
      }
    });

    return completer.future;
  }

  void stopListening() {
    if (_speech.isListening) {
      _speech.stop();
    }
  }

  bool get isInitialized => _isInitialized;
  bool get isListening => _speech.isListening;
}
