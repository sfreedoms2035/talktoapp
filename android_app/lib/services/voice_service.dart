import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// Note: We attempted to implement Whisper for potentially better speech recognition,
// but encountered API compatibility issues. The current implementation uses speech_to_text
// which provides reliable speech recognition capabilities.

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isContinuousListening = false;
  String _lastRecognizedText = '';
  Function(String)? onTextRecognized; // Callback for text recognition updates
  static const String TRIGGER_WORD = 'hey';
  static const String STOP_WORD = 'stop';

  Future<void> initialize() async {
    try {
      print('Initializing speech recognition...');
      _isInitialized = await _speech.initialize(
        onError: (error) {
          print('Speech recognition error: $error');
        },
        onStatus: (status) {
          print('Speech recognition status: $status');
          if (status == 'done') {
            _isListening = false;
          } else if (status == 'listening') {
            _isListening = true;
          }
        },
        debugLogging: true, // Enable debug logging for better troubleshooting
      );
      print('Speech recognition initialized: $_isInitialized');
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
    _lastRecognizedText = '';

    try {
      print('Starting speech recognition...');
      _isListening = true;
      
      _speech.listen(
        onResult: (result) {
          recognizedText = result.recognizedWords;
          _lastRecognizedText = recognizedText;
          print('Setting last recognized text in listen: $recognizedText');
          
          // Always call callback to update UI with recognized text, even for partial results
          if (onTextRecognized != null) {
            print('Calling onTextRecognized callback in listen with: $recognizedText');
            onTextRecognized!(recognizedText);
          } else {
            print('Warning: onTextRecognized callback is null in listen');
          }
          print('Recognized text: $recognizedText');
          
          // Check for trigger word
          if (recognizedText.toLowerCase().contains(TRIGGER_WORD.toLowerCase())) {
            print('Trigger word detected: $TRIGGER_WORD');
            _speech.stop();
            completer.complete(TRIGGER_WORD);
            return;
          }
          
          // Complete on final result for better responsiveness
          if (result.finalResult) {
            print('Final result: $recognizedText');
            _speech.stop();
            completer.complete(recognizedText);
          }
        },
        listenFor: const Duration(seconds: 15), // Longer listening time
        pauseFor: const Duration(seconds: 2), // Shorter pause time
        localeId: 'en_US',
      );
    } catch (e) {
      print('Error in speech recognition: $e');
      _isListening = false;
      completer.completeError(e);
    }

    // Set a timeout
    Future.delayed(const Duration(seconds: 20), () {
      if (!completer.isCompleted) {
        print('Speech recognition timeout');
        _speech.stop();
        _isListening = false;
        completer.complete('');
      }
    });

    return completer.future;
  }

  Future<bool> listenForTriggerWord() async {
    if (!_isInitialized) {
      throw Exception('Speech recognition not initialized');
    }

    final completer = Completer<bool>();
    bool triggerDetected = false;

    try {
      print('Listening for trigger word: $TRIGGER_WORD');
      _isListening = true;
      
      _speech.listen(
        onResult: (result) {
          final recognizedText = result.recognizedWords;
          _lastRecognizedText = recognizedText;
          print('Setting last recognized text: $recognizedText');
          
          // Always call callback to update UI with recognized text, even for partial results
          if (onTextRecognized != null) {
            print('Calling onTextRecognized callback with: $recognizedText');
            onTextRecognized!(recognizedText);
          } else {
            print('Warning: onTextRecognized callback is null');
          }
          print('Heard: $recognizedText');
          
          // Check for trigger word with more flexible matching
          final normalizedText = recognizedText.toLowerCase().trim();
          // More sensitive trigger detection - just look for "hey" anywhere in the text
          // Also check for partial matches and alternative forms
          if (normalizedText.contains(TRIGGER_WORD) || 
              normalizedText.contains('hey there') ||
              normalizedText.contains('hey you')) {
            print('Trigger word detected: $TRIGGER_WORD in text: $recognizedText');
            triggerDetected = true;
            _speech.stop();
            completer.complete(true);
            return;
          }
          
          // Also check partial results for better responsiveness
          // But don't stop listening on final result, continue for better accuracy
          if (result.finalResult && !triggerDetected) {
            print('Final result received, no trigger detected: $recognizedText');
          }
        },
        listenFor: const Duration(seconds: 30), // Longer listening time for better detection
        pauseFor: const Duration(milliseconds: 200), // Very short pause for more responsive detection
        localeId: 'en_US',
      );
    } catch (e) {
      print('Error listening for trigger word: $e');
      _isListening = false;
      completer.completeError(e);
    }

    // Set a timeout
    Future.delayed(const Duration(seconds: 35), () {
      if (!completer.isCompleted) {
        print('Trigger word detection timeout');
        _speech.stop();
        _isListening = false;
        completer.complete(false);
      }
    });

    return completer.future;
  }

  Future<String> listenUntilStopWord() async {
    if (!_isInitialized) {
      throw Exception('Speech recognition not initialized');
    }

    final completer = Completer<String>();
    final StringBuffer fullTranscript = StringBuffer();
    bool stopDetected = false;

    try {
      print('Listening until stop word...');
      _isListening = true;
      
      _speech.listen(
        onResult: (result) {
          final recognizedText = result.recognizedWords;
          _lastRecognizedText = recognizedText;
          print('Setting last recognized text in listenUntilStopWord: $recognizedText');
          
          // Always call callback to update UI with recognized text, even for partial results
          if (onTextRecognized != null) {
            print('Calling onTextRecognized callback in listenUntilStopWord with: $recognizedText');
            onTextRecognized!(recognizedText);
          } else {
            print('Warning: onTextRecognized callback is null in listenUntilStopWord');
          }
          print('Heard: $recognizedText');
          
          // Add to full transcript
          if (recognizedText.isNotEmpty) {
            if (fullTranscript.isNotEmpty) {
              fullTranscript.write(' ');
            }
            fullTranscript.write(recognizedText);
          }
          
          // Check for stop word with more flexible matching
          final normalizedText = recognizedText.toLowerCase().trim();
          if (normalizedText.contains('stop') || normalizedText.endsWith('stop')) {
            print('Stop word detected in text: $recognizedText');
            stopDetected = true;
            _speech.stop();
            completer.complete(fullTranscript.toString());
            return;
          }
          
          // If it's a final result and no stop word, continue listening
          if (result.finalResult && !stopDetected) {
            print('Final result received, continuing to listen...');
          }
        },
        listenFor: const Duration(seconds: 20), // Increased listening time
        pauseFor: const Duration(seconds: 1), // Shorter pause time for better responsiveness
        localeId: 'en_US',
      );
    } catch (e) {
      print('Error in continuous listening: $e');
      _isListening = false;
      completer.completeError(e);
    }

    // Set a timeout
    Future.delayed(const Duration(seconds: 25), () { // Adjusted timeout
      if (!completer.isCompleted) {
        print('Continuous listening timeout');
        _speech.stop();
        _isListening = false;
        completer.complete(fullTranscript.toString());
      }
    });

    return completer.future;
  }

  /// Start continuous listening for trigger word detection
  Future<void> startContinuousListening() async {
    if (!_isInitialized) {
      throw Exception('Speech recognition not initialized');
    }

    print('Starting continuous listening for trigger word detection...');
    _isContinuousListening = true;
    
    // Set up continuous listening loop
    _continuousListeningLoop();
  }

  /// Continuous listening loop that restarts automatically
  void _continuousListeningLoop() async {
    print('Starting continuous listening loop...');
    
    while (_isContinuousListening) {
      try {
        print('Starting new listening session for continuous listening...');
        
        // Use the regular listen method instead of listenForTriggerWord for better reliability
        final text = await listen();
        
        print('Continuous listening received text: $text');
        
        if (text.isNotEmpty) {
          // Check for trigger word
          if (text.toLowerCase().contains(TRIGGER_WORD.toLowerCase())) {
            print('Trigger word detected in continuous listening: $TRIGGER_WORD');
            // The trigger detection will be handled by the callback in the home screen
          }
          
          // Continue listening after a short delay
          await Future.delayed(const Duration(milliseconds: 500));
        }
        
        // Small delay before restarting listening to prevent excessive CPU usage
        if (_isContinuousListening) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } catch (e) {
        print('Error in continuous listening loop: $e');
        // Wait a bit before retrying
        if (_isContinuousListening) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
    
    print('Continuous listening loop ended');
  }

  void stopListening() {
    print('Stopping speech recognition and continuous listening');
    _isContinuousListening = false;
    if (_speech.isListening) {
      _speech.stop();
      _isListening = false;
    }
  }

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get lastRecognizedText => _lastRecognizedText;
  String get triggerWord => TRIGGER_WORD;
}
