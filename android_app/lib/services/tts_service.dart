import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  TtsService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Set up TTS properties with American English voice
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.6); // Slightly faster for more natural flow
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.1); // Slightly higher pitch for clearer voice
      
      // Try to set a specific voice if available
      try {
        final voices = await _flutterTts.getVoices;
        if (voices != null) {
          // Look for a high quality American English voice and avoid German voices
          for (var voice in voices) {
            if (voice.name != null && 
                (voice.name!.contains('en-US') || voice.name!.contains('English')) &&
                !voice.name!.contains('de-DE') && !voice.name!.contains('German')) {
              await _flutterTts.setVoice(voice);
              break;
            }
          }
        }
      } catch (e) {
        print('Could not set specific voice: $e');
      }
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing TTS: $e');
      _isInitialized = false;
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      throw Exception('TTS not initialized');
    }
    
    if (text.isEmpty) {
      return;
    }
    
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print('Error speaking text: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('Error stopping TTS: $e');
    }
  }

  Future<List<String>> getLanguages() async {
    try {
      return await _flutterTts.getLanguages;
    } catch (e) {
      print('Error getting languages: $e');
      return [];
    }
  }

  Future<void> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
    } catch (e) {
      print('Error setting language: $e');
    }
  }

  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (e) {
      print('Error setting speech rate: $e');
    }
  }

  bool get isInitialized => _isInitialized;
}
