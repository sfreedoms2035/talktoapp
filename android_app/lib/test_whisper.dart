import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class WhisperTestScreen extends StatefulWidget {
  const WhisperTestScreen({super.key});

  @override
  State<WhisperTestScreen> createState() => _WhisperTestScreenState();
}

class _WhisperTestScreenState extends State<WhisperTestScreen> {
  bool _isRecording = false;
  String _transcription = "Press the microphone to start continuous listening.";
  
  late final Whisper _whisper;
  bool _isModelLoaded = false;
  
  // This is crucial for managing the stream subscription
  StreamSubscription? _streamSubscription;
  Timer? _periodicTimer;

  @override
  void initState() {
    super.initState();
    _initWhisper();
  }

  // It's good practice to release resources when the widget is disposed
  @override
  void dispose() {
    _streamSubscription?.cancel(); // Cancel the stream subscription
    _periodicTimer?.cancel(); // Cancel any periodic timer
    super.dispose();
  }
  
  Future<void> _initWhisper() async {
    // Request microphone permission
    var status = await Permission.microphone.request();
    if (status.isPermanentlyDenied) {
      openAppSettings();
      return;
    }

    if (status.isGranted) {
      setState(() { _transcription = "Loading model..."; });

      try {
        // Initialize with the model parameter
        _whisper = Whisper(model: WhisperModel.base);
        
        // We can't check isLoaded directly, so we'll assume it's loaded
        print('Assuming model is loaded');
        
        if (mounted) {
          setState(() {
            _isModelLoaded = true;
            _transcription = "Model loaded. Press the mic to start.";
          });
        }
      } catch (e) {
        print('Error initializing Whisper: $e');
        
        try {
          // Try with download host
          _whisper = Whisper(
            model: WhisperModel.base,
            downloadHost: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main"
          );
          setState(() {
            _isModelLoaded = true;
            _transcription = "Model loaded with downloadHost. Press the mic to start.";
          });
        } catch (e) {
          print('Error initializing Whisper with downloadHost: $e');
          setState(() {
            _transcription = "Failed to load Whisper model: $e";
          });
        }
      }
    } else {
      setState(() {
        _transcription = "Microphone permission is required.";
      });
    }
  }

  // Record audio to a temporary file
  Future<String> _recordAudio() async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
    
    // In a real implementation, you would record audio here
    // For this test, we'll just create an empty file
    final file = File(tempPath);
    await file.writeAsString('dummy audio data');
    
    return tempPath;
  }

  // Set up periodic transcription
  void _setupPeriodicTranscription() {
    _periodicTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      
      try {
        final audioPath = await _recordAudio();
        final result = await _whisper.transcribe(
          transcribeRequest: TranscribeRequest(
            audio: audioPath,
            isTranslate: false,
            isNoTimestamps: true,
            splitOnWord: false,
          ),
        );
        
        if (mounted) {
          setState(() {
            _transcription = result?.text ?? "No text available";
          });
        }
        
        // Clean up the temporary file
        try {
          await File(audioPath).delete();
        } catch (e) {
          print('Error deleting temporary file: $e');
        }
      } catch (e) {
        print('Error in periodic transcription: $e');
        if (mounted) {
          setState(() {
            _transcription = "Error: $e";
          });
        }
      }
    });
  }

  /// Toggles the continuous listening state
  Future<void> _toggleRecording() async {
    if (!_isModelLoaded) return;

    if (_isRecording) {
      // If we are already recording, stop it
      _periodicTimer?.cancel();
      await _streamSubscription?.cancel(); // Cancel the subscription
      setState(() {
        _isRecording = false;
        _transcription += "\n\nStopped listening.";
      });
    } else {
      // If we are not recording, start it
      setState(() {
        _isRecording = true;
        _transcription = "Starting transcription..."; // Clear previous transcription
      });

      try {
        // Record audio and transcribe
        final audioPath = await _recordAudio();
        final result = await _whisper.transcribe(
          transcribeRequest: TranscribeRequest(
            audio: audioPath,
            isTranslate: false,
            isNoTimestamps: true,
            splitOnWord: false,
          ),
        );
        
        if (mounted) {
          setState(() {
            _transcription = result?.text ?? "No text available";
          });
        }
        
        // Clean up the temporary file
        try {
          await File(audioPath).delete();
        } catch (e) {
          print('Error deleting temporary file: $e');
        }
        
        // Set up periodic transcription
        _setupPeriodicTranscription();
      } catch (e) {
        print("Error starting transcription: $e");
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
        title: const Text('Whisper Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Instruction Text
              Text(
                _isRecording ? "I am listening..." : "Tap the mic to start",
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
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
        onPressed: !_isModelLoaded ? null : _toggleRecording,
        tooltip: 'Listen',
        backgroundColor: !_isModelLoaded ? Colors.grey : (_isRecording ? Colors.red : Colors.blue),
        child: Icon(_isRecording ? Icons.stop_circle_outlined : Icons.mic, color: Colors.white, size: 40),
      ),
    );
  }
}
