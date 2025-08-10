import 'package:flutter/material.dart';
import 'services/whisper_service_new.dart';

/// A screen to test the new Whisper service implementation.
class WhisperNewTestScreen extends StatefulWidget {
  const WhisperNewTestScreen({super.key});

  @override
  State<WhisperNewTestScreen> createState() => _WhisperNewTestScreenState();
}

class _WhisperNewTestScreenState extends State<WhisperNewTestScreen> {
  bool _isRecording = false;
  String _transcription = "Press the microphone to start continuous listening.";
  
  late final WhisperService _whisperService;
  bool _isServiceInitialized = false;
  bool _isInitializing = false;
  
  @override
  void initState() {
    super.initState();
    _initWhisperService();
  }

  @override
  void dispose() {
    _whisperService.dispose();
    super.dispose();
  }
  
  /// Initialize the Whisper service
  Future<void> _initWhisperService() async {
    setState(() {
      _isInitializing = true;
      _transcription = "Initializing Whisper service...";
    });
    
    try {
      _whisperService = WhisperService();
      
      // Set up callback for recognized text
      _whisperService.onTextRecognized = (text) {
        if (mounted) {
          setState(() {
            _transcription = text;
          });
        }
      };
      
      // Initialize the service
      await _whisperService.initialize();
      
      if (mounted) {
        setState(() {
          _isServiceInitialized = true;
          _isInitializing = false;
          _transcription = "Whisper service initialized. Press the mic to start.";
        });
      }
    } catch (e) {
      print('Error initializing Whisper service: $e');
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _transcription = "Failed to initialize Whisper service: $e";
        });
      }
    }
  }

  /// Toggle recording state
  Future<void> _toggleRecording() async {
    if (!_isServiceInitialized) {
      setState(() {
        _transcription = "Service not initialized yet. Please wait.";
      });
      return;
    }

    if (_isRecording) {
      // If we are already recording, stop it
      try {
        print("Stopping Whisper listening...");
        await _whisperService.stopListening();
        setState(() {
          _isRecording = false;
          _transcription += "\n\nStopped listening.";
        });
        print("Whisper listening stopped successfully");
      } catch (e, stackTrace) {
        print("Error stopping recording: $e");
        print("Stack trace: $stackTrace");
        setState(() {
          _isRecording = false; // Make sure to set this to false even if there's an error
          _transcription = "Error: Could not stop listening. $e";
        });
      }
    } else {
      // If we are not recording, start it
      setState(() {
        _isRecording = true;
        _transcription = "Starting transcription..."; // Clear previous transcription
      });

      try {
        print("Starting Whisper continuous listening...");
        
        // Check if the service is properly initialized
        if (!_whisperService.isInitialized) {
          print("Whisper service is not initialized. Reinitializing...");
          await _whisperService.initialize();
        }
        
        // Check if the model is loaded
        if (!_whisperService.isModelLoaded) {
          print("Whisper model is not loaded. This might cause issues.");
        }
        
        // Start continuous listening with a try-catch block
        try {
          await _whisperService.startContinuousListening();
          print("Whisper continuous listening started successfully");
        } catch (e) {
          throw Exception("Failed to start continuous listening: $e");
        }
      } catch (e, stackTrace) {
        print("Error starting recording: $e");
        print("Stack trace: $stackTrace");
        setState(() {
          _isRecording = false;
          _transcription = "Error: Could not start listener. $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Whisper Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Status Text
              Text(
                _isInitializing 
                  ? "Initializing..." 
                  : (_isRecording ? "I am listening..." : "Tap the mic to start"),
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              
              // Back to Home Button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Back to Home Screen'),
              ),
              const SizedBox(height: 10),
              // Transcription Display Area
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _transcription,
                      style: const TextStyle(fontSize: 22.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.large(
        onPressed: _isInitializing || !_isServiceInitialized ? null : _toggleRecording,
        tooltip: 'Listen',
        backgroundColor: _isInitializing || !_isServiceInitialized 
          ? Colors.grey 
          : (_isRecording ? Colors.red : Colors.blue),
        child: Icon(
          _isRecording ? Icons.stop_circle_outlined : Icons.mic, 
          color: Colors.white, 
          size: 40
        ),
      ),
    );
  }
}
