import 'package:flutter_tts/flutter_tts.dart';

/// Singleton TTS service to ensure consistent voice across all screens
class SharedTtsService {
  static final SharedTtsService _instance = SharedTtsService._internal();
  factory SharedTtsService() => _instance;
  SharedTtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('Initializing shared TTS service...');
      
      // Set up TTS properties with consistent voice settings
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.6); // Consistent speech rate
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.1); // Consistent pitch
      
      // Try to set a specific high-quality voice
      try {
        final voices = await _flutterTts.getVoices;
        if (voices != null) {
          print('Available voices: ${voices.length}');
          
          // Look for the best English voice
          for (var voice in voices) {
            print('Voice: ${voice.name}, Locale: ${voice.locale}');
            
            // Prefer high-quality English voices
            if (voice.name != null && voice.locale != null) {
              final name = voice.name!.toLowerCase();
              final locale = voice.locale!.toLowerCase();
              
              if ((locale.contains('en-us') || locale.contains('en_us')) &&
                  (name.contains('enhanced') || name.contains('premium') || 
                   name.contains('neural') || name.contains('quality'))) {
                print('Setting high-quality voice: ${voice.name}');
                await _flutterTts.setVoice(voice);
                break;
              }
            }
          }
        }
      } catch (e) {
        print('Could not set specific voice: $e');
      }
      
      _isInitialized = true;
      print('Shared TTS service initialized successfully');
    } catch (e) {
      print('Error initializing shared TTS: $e');
      _isInitialized = false;
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (text.isEmpty) {
      return;
    }
    
    try {
      print('Speaking: $text');
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

  bool get isInitialized => _isInitialized;
}
