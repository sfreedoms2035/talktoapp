import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class WhisperService {
  // Whisper model instance
  late final Whisper _whisper;
  
  // Flutter Sound recorder for audio capture
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  
  // Stream subscription for audio data
  StreamSubscription? _recorderSubscription;
  
  // Buffer for audio data
  List<int> _audioBuffer = [];
  
  // State variables
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isModelLoaded = false;
  String _lastRecognizedText = '';
  
  // Callback for text recognition updates
  Function(String)? onTextRecognized;
  
  // Constants
  static const String TRIGGER_WORD = 'hey';
  static const String STOP_WORD = 'stop';
  
  // Initialize the service
  Future<void> initialize() async {
    try {
      print('Initializing Whisper service...');
      
      // Request microphone permission
      var status = await Permission.microphone.request();
      if (status.isPermanentlyDenied) {
        print('Microphone permission permanently denied');
        throw Exception('Microphone permission permanently denied');
      }
      
      if (!status.isGranted) {
        print('Microphone permission not granted');
        throw Exception('Microphone permission not granted');
      }
      
      // Initialize the recorder
      await _recorder.openRecorder();
      
      // Initialize Whisper
      print('Loading Whisper model...');
      try {
        // Try to load the model from assets
        _whisper = Whisper(model: WhisperModel.base);
        
        // Assume model is loaded since we can't check directly
        _isModelLoaded = true;
        print('Whisper model assumed to be loaded');
      } catch (e) {
        print('Error initializing Whisper: $e');
        throw Exception('Failed to initialize Whisper: $e');
      }
      
      _isInitialized = true;
      print('Whisper service initialized');
    } catch (e) {
      print('Error initializing Whisper service: $e');
      _isInitialized = false;
      throw Exception('Failed to initialize Whisper service: $e');
    }
  }
  
  // Start continuous listening with Whisper
  Future<void> startContinuousListening() async {
    if (!_isInitialized) {
      throw Exception('Whisper service not initialized');
    }
    
    if (_isRecording) {
      print('Already recording');
      return;
    }
    
    try {
      print('Starting continuous listening with Whisper...');
      _isRecording = true;
      _lastRecognizedText = '';
      
      // Start the foreground service
      await _startForegroundService();
      
      // Start recording to a file
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/continuous_recording.wav';
      
      await _recorder.startRecorder(
        toFile: tempPath,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 16000,
      );
      
      // Set up periodic transcription
      _setupPeriodicTranscription();
      
      print('Continuous listening started');
    } catch (e) {
      print('Error starting continuous listening: $e');
      _isRecording = false;
      throw Exception('Failed to start continuous listening: $e');
    }
  }
  
  // Set up periodic transcription
  void _setupPeriodicTranscription() {
    // Create a timer that periodically stops recording, transcribes, and starts recording again
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      
      try {
        // Stop recording temporarily
        final recordedFile = await _recorder.stopRecorder();
        
        if (recordedFile != null) {
          // Transcribe the recorded audio
          await _transcribeFile(recordedFile);
          
          // Start recording again if still in recording state
          if (_isRecording) {
            await _recorder.startRecorder(
              toFile: recordedFile,
              codec: Codec.pcm16,
              numChannels: 1,
              sampleRate: 16000,
            );
          }
        }
      } catch (e) {
        print('Error in periodic transcription: $e');
      }
    });
  }
  
  // Transcribe a file
  Future<void> _transcribeFile(String filePath) async {
    try {
      print('Transcribing file: $filePath');
      
      // Transcribe the file
      final result = await _whisper.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: filePath,
          isTranslate: false,
          isNoTimestamps: true,
          splitOnWord: false,
        ),
      );
      
      // Update last recognized text
      if (result != null && result.text != null && result.text!.isNotEmpty) {
        _lastRecognizedText = result.text!;
        
        // Call callback to update UI with recognized text
        if (onTextRecognized != null) {
          onTextRecognized!(_lastRecognizedText);
        }
        
        print('Transcribed text: $_lastRecognizedText');
        
        // Check for trigger word
        if (_lastRecognizedText.toLowerCase().contains(TRIGGER_WORD.toLowerCase())) {
          print('Trigger word detected: $TRIGGER_WORD');
        }
        
        // Check for stop word
        if (_lastRecognizedText.toLowerCase().contains(STOP_WORD.toLowerCase())) {
          print('Stop word detected: $STOP_WORD');
        }
        
        // Update foreground service notification
        if (await FlutterForegroundTask.isRunningService) {
          FlutterForegroundTask.updateService(
            notificationTitle: 'Whisper Transcription',
            notificationText: _lastRecognizedText.isNotEmpty ? _lastRecognizedText : 'Listening...',
          );
        }
      }
    } catch (e) {
      print('Error transcribing file: $e');
    }
  }
  
  // Stop listening
  Future<void> stopListening() async {
    if (!_isRecording) {
      return;
    }
    
    try {
      print('Stopping Whisper listening...');
      
      // Set recording flag to false to stop periodic transcription
      _isRecording = false;
      
      // Stop recording
      await _recorder.stopRecorder();
      
      // Cancel subscription
      await _recorderSubscription?.cancel();
      _recorderSubscription = null;
      
      // Stop foreground service
      await _stopForegroundService();
      
      print('Whisper listening stopped');
    } catch (e) {
      print('Error stopping Whisper listening: $e');
    }
  }
  
  // Start foreground service
  Future<void> _startForegroundService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return;
    }
    
    // Initialize foreground task
    _initForegroundTask();
    
    // Start service
    await FlutterForegroundTask.startService(
      notificationTitle: 'Whisper Transcription',
      notificationText: 'Listening...',
      callback: () {
        FlutterForegroundTask.setTaskHandler(WhisperTaskHandler(
          onTranscriptionUpdate: (text) {
            _lastRecognizedText = text;
            if (onTextRecognized != null) {
              onTextRecognized!(text);
            }
          },
        ));
      },
    );
  }
  
  // Initialize foreground task
  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'whisper_transcription',
        channelName: 'Whisper Transcription',
        channelDescription: 'This notification appears when the Whisper transcription service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        // Use a simpler notification without custom icon
        // to avoid compatibility issues
        enableVibration: false,
        playSound: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }
  
  // Stop foreground service
  Future<void> _stopForegroundService() async {
    await FlutterForegroundTask.stopService();
  }
  
  // Dispose resources
  Future<void> dispose() async {
    await stopListening();
    await _recorder.closeRecorder();
  }
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;
  bool get isModelLoaded => _isModelLoaded;
  String get lastRecognizedText => _lastRecognizedText;
  String get triggerWord => TRIGGER_WORD;
}

// Task handler for foreground service
class WhisperTaskHandler extends TaskHandler {
  final Function(String)? onTranscriptionUpdate;
  
  WhisperTaskHandler({this.onTranscriptionUpdate});
  
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // Update notification
    FlutterForegroundTask.updateService(
      notificationTitle: 'Whisper Transcription',
      notificationText: 'Listening...',
    );
  }
  
  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // This is called periodically
    // You can update the notification here
  }
  
  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // Clean up resources
  }
  
  // Update transcription
  void updateTranscription(String text) {
    // Update notification
    FlutterForegroundTask.updateService(
      notificationTitle: 'Whisper Transcription',
      notificationText: text.isNotEmpty ? text : 'Listening...',
    );
    
    // Call callback
    if (onTranscriptionUpdate != null) {
      onTranscriptionUpdate!(text);
    }
  }
}
