import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// A service that provides speech recognition using the Whisper model.
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
  
  // ReceivePort for communication with the foreground task
  ReceivePort? _receivePort;
  
  // Constants
  static const String TRIGGER_WORD = 'hey';
  static const String STOP_WORD = 'stop';
  
  /// Initialize the service
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
        // Try to load the model
        _whisper = Whisper(model: WhisperModel.base);
        
        // Assume model is loaded since we can't check directly
        _isModelLoaded = true;
        print('Whisper model assumed to be loaded');
      } catch (e) {
        print('Error initializing Whisper: $e');
        
        // Try with download host as fallback
        try {
          _whisper = Whisper(
            model: WhisperModel.base,
            downloadHost: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main"
          );
          _isModelLoaded = true;
          print('Whisper model loaded with downloadHost');
        } catch (e) {
          print('Error initializing Whisper with downloadHost: $e');
          throw Exception('Failed to initialize Whisper: $e');
        }
      }
      
      // Initialize foreground task
      _initForegroundTask();
      
      // Initialize receive port
      await _initReceivePort();
      
      _isInitialized = true;
      print('Whisper service initialized');
    } catch (e) {
      print('Error initializing Whisper service: $e');
      _isInitialized = false;
      throw Exception('Failed to initialize Whisper service: $e');
    }
  }
  
  /// Initialize the receive port for communication with the foreground task
  Future<void> _initReceivePort() async {
    _receivePort = await FlutterForegroundTask.receivePort;
    _receivePort?.listen((dynamic data) {
      if (data is String) {
        _lastRecognizedText = data;
        if (onTextRecognized != null) {
          onTextRecognized!(data);
        }
      }
    });
  }
  
  /// Initialize the foreground task
  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'whisper_transcription',
        channelName: 'Whisper Transcription',
        channelDescription: 'This notification appears when the Whisper transcription service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
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
  
  /// Start continuous listening with Whisper
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
      
      print('Continuous listening started');
    } catch (e) {
      print('Error starting continuous listening: $e');
      _isRecording = false;
      throw Exception('Failed to start continuous listening: $e');
    }
  }
  
  /// Start the foreground service
  Future<void> _startForegroundService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return;
    }
    
    // Start service
    await FlutterForegroundTask.startService(
      notificationTitle: 'Whisper Transcription',
      notificationText: 'Listening...',
      callback: () {
        // Set the task handler
        FlutterForegroundTask.setTaskHandler(WhisperTaskHandler(
          whisperModel: WhisperModel.base,
        ));
      },
    );
  }
  
  /// Stop listening
  Future<void> stopListening() async {
    if (!_isRecording) {
      return;
    }
    
    try {
      print('Stopping Whisper listening...');
      
      // Set recording flag to false
      _isRecording = false;
      
      // Stop foreground service
      await _stopForegroundService();
      
      print('Whisper listening stopped');
    } catch (e) {
      print('Error stopping Whisper listening: $e');
    }
  }
  
  /// Stop the foreground service
  Future<void> _stopForegroundService() async {
    await FlutterForegroundTask.stopService();
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await stopListening();
    await _recorder.closeRecorder();
    _receivePort?.close();
  }
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;
  bool get isModelLoaded => _isModelLoaded;
  String get lastRecognizedText => _lastRecognizedText;
  String get triggerWord => TRIGGER_WORD;
}

/// Task handler for the foreground service
class WhisperTaskHandler extends TaskHandler {
  final WhisperModel whisperModel;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  StreamSubscription? _recorderSubscription;
  late final Whisper _whisper;
  String _transcribedText = "";
  List<int> _audioBuffer = [];
  Timer? _processingTimer;
  bool _isProcessing = false;
  
  WhisperTaskHandler({
    required this.whisperModel,
  });
  
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    print('WhisperTaskHandler: onStart');
    
    try {
      // Initialize Whisper with better error handling
      try {
        print('Initializing Whisper model in task handler...');
        _whisper = Whisper(model: whisperModel);
        print('Whisper model initialized successfully in task handler');
      } catch (e) {
        print('Error initializing Whisper in task handler: $e');
        
        // Try with download host as fallback
        try {
          print('Trying with downloadHost as fallback...');
          _whisper = Whisper(
            model: whisperModel,
            downloadHost: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main"
          );
          print('Whisper model initialized with downloadHost in task handler');
        } catch (e) {
          print('Error initializing Whisper with downloadHost in task handler: $e');
          sendPort?.send("Error initializing Whisper: $e");
          throw Exception('Failed to initialize Whisper in task handler: $e');
        }
      }
      
      // Initialize recorder
      try {
        print('Opening recorder in task handler...');
        await _recorder.openRecorder();
        print('Recorder opened successfully in task handler');
      } catch (e) {
        print('Error opening recorder in task handler: $e');
        sendPort?.send("Error opening recorder: $e");
        throw Exception('Failed to open recorder in task handler: $e');
      }
      
      // Start recording
      await _startRecording(sendPort);
      
      // Update notification
      FlutterForegroundTask.updateService(
        notificationTitle: 'Whisper Transcription',
        notificationText: 'Listening...',
      );
    } catch (e, stackTrace) {
      print('Error in onStart: $e');
      print('Stack trace: $stackTrace');
      
      // Send error to main UI
      sendPort?.send("Error starting Whisper service: $e");
      
      FlutterForegroundTask.updateService(
        notificationTitle: 'Whisper Transcription',
        notificationText: 'Error: $e',
      );
    }
  }
  
  /// Start recording audio
  Future<void> _startRecording(SendPort? sendPort) async {
    try {
      print('Starting recording in task handler...');
      
      // Create a stream controller for audio data
      final StreamController<Uint8List> recordingDataController = StreamController<Uint8List>();
      
      // Listen to the audio stream
      _recorderSubscription = recordingDataController.stream.listen((buffer) {
        _processAudioBuffer(buffer, sendPort);
      }, onError: (error) {
        print('Error in audio stream: $error');
        sendPort?.send("Error in audio stream: $error");
      });
      
      // Start recording with error handling
      try {
        await _recorder.startRecorder(
          toStream: recordingDataController.sink,
          codec: Codec.pcm16,
          numChannels: 1,
          sampleRate: 16000,
        );
        print('Recorder started successfully in task handler');
      } catch (e) {
        print('Error starting recorder in task handler: $e');
        sendPort?.send("Error starting recorder: $e");
        throw e;
      }
      
      // Start a timer to periodically process the audio buffer
      _processingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (_audioBuffer.isNotEmpty && !_isProcessing) {
          _transcribeBufferAsync(sendPort);
        }
      });
      
      print('Recording started');
    } catch (e) {
      print('Error starting recording: $e');
    }
  }
  
  /// Process audio buffer
  void _processAudioBuffer(Uint8List buffer, SendPort? sendPort) {
    // Add data to buffer
    _audioBuffer.addAll(buffer);
    
    // When buffer reaches a certain size (e.g., 5 seconds of audio at 16kHz)
    if (_audioBuffer.length > 16000 * 5 * 2 && !_isProcessing) { // 5 seconds of 16kHz 16-bit audio
      _transcribeBufferAsync(sendPort);
    }
  }
  
  /// Transcribe buffer asynchronously
  Future<void> _transcribeBufferAsync(SendPort? sendPort) async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    
    // Make a copy of the buffer and clear it
    final List<int> bufferCopy = List.from(_audioBuffer);
    _audioBuffer.clear();
    
    // Process in a separate async function to not block the audio stream
    await _transcribeBuffer(bufferCopy, sendPort);
    
    _isProcessing = false;
  }
  
  /// Transcribe buffer
  Future<void> _transcribeBuffer(List<int> buffer, SendPort? sendPort) async {
    try {
      // Write buffer to temporary WAV file
      final tempPath = await _writeBufferToTempFile(buffer);
      
      // Transcribe the file
      final result = await _whisper.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: tempPath,
          isTranslate: false,
          isNoTimestamps: true,
          splitOnWord: false,
        ),
      );
      
      // Update transcribed text
      if (result != null && result.text != null && result.text!.isNotEmpty) {
        _transcribedText = result.text!;
        
        // Send transcribed text to the main UI
        sendPort?.send(_transcribedText);
        
        print('Transcribed text: $_transcribedText');
        
        // Update notification
        FlutterForegroundTask.updateService(
          notificationTitle: 'Whisper Transcription',
          notificationText: _transcribedText.isNotEmpty ? _transcribedText : 'Listening...',
        );
        
        // Check for trigger word
        if (_transcribedText.toLowerCase().contains(WhisperService.TRIGGER_WORD.toLowerCase())) {
          print('Trigger word detected: ${WhisperService.TRIGGER_WORD}');
        }
        
        // Check for stop word
        if (_transcribedText.toLowerCase().contains(WhisperService.STOP_WORD.toLowerCase())) {
          print('Stop word detected: ${WhisperService.STOP_WORD}');
        }
      }
      
      // Delete temporary file
      File(tempPath).deleteSync();
    } catch (e) {
      print('Error transcribing buffer: $e');
    }
  }
  
  /// Write buffer to temporary WAV file
  Future<String> _writeBufferToTempFile(List<int> buffer) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      // Create WAV file
      final file = File(tempPath);
      final sink = file.openWrite();
      
      // Write WAV header
      sink.add(_createWavHeader(buffer.length));
      
      // Write audio data
      sink.add(buffer);
      
      // Close file
      await sink.close();
      
      return tempPath;
    } catch (e) {
      print('Error writing buffer to temp file: $e');
      throw Exception('Failed to write buffer to temp file: $e');
    }
  }
  
  /// Create WAV header
  List<int> _createWavHeader(int dataLength) {
    final header = List<int>.filled(44, 0);
    
    // RIFF chunk descriptor
    header[0] = 'R'.codeUnitAt(0);
    header[1] = 'I'.codeUnitAt(0);
    header[2] = 'F'.codeUnitAt(0);
    header[3] = 'F'.codeUnitAt(0);
    
    // Chunk size
    final chunkSize = dataLength + 36;
    header[4] = chunkSize & 0xFF;
    header[5] = (chunkSize >> 8) & 0xFF;
    header[6] = (chunkSize >> 16) & 0xFF;
    header[7] = (chunkSize >> 24) & 0xFF;
    
    // Format
    header[8] = 'W'.codeUnitAt(0);
    header[9] = 'A'.codeUnitAt(0);
    header[10] = 'V'.codeUnitAt(0);
    header[11] = 'E'.codeUnitAt(0);
    
    // Subchunk1 ID
    header[12] = 'f'.codeUnitAt(0);
    header[13] = 'm'.codeUnitAt(0);
    header[14] = 't'.codeUnitAt(0);
    header[15] = ' '.codeUnitAt(0);
    
    // Subchunk1 size
    header[16] = 16;
    header[17] = 0;
    header[18] = 0;
    header[19] = 0;
    
    // Audio format (PCM)
    header[20] = 1;
    header[21] = 0;
    
    // Number of channels (1)
    header[22] = 1;
    header[23] = 0;
    
    // Sample rate (16000 Hz)
    header[24] = 16000 & 0xFF;
    header[25] = (16000 >> 8) & 0xFF;
    header[26] = (16000 >> 16) & 0xFF;
    header[27] = (16000 >> 24) & 0xFF;
    
    // Byte rate (16000 * 1 * 16/8)
    final byteRate = 16000 * 2;
    header[28] = byteRate & 0xFF;
    header[29] = (byteRate >> 8) & 0xFF;
    header[30] = (byteRate >> 16) & 0xFF;
    header[31] = (byteRate >> 24) & 0xFF;
    
    // Block align (1 * 16/8)
    header[32] = 2;
    header[33] = 0;
    
    // Bits per sample (16)
    header[34] = 16;
    header[35] = 0;
    
    // Subchunk2 ID
    header[36] = 'd'.codeUnitAt(0);
    header[37] = 'a'.codeUnitAt(0);
    header[38] = 't'.codeUnitAt(0);
    header[39] = 'a'.codeUnitAt(0);
    
    // Subchunk2 size
    header[40] = dataLength & 0xFF;
    header[41] = (dataLength >> 8) & 0xFF;
    header[42] = (dataLength >> 16) & 0xFF;
    header[43] = (dataLength >> 24) & 0xFF;
    
    return header;
  }
  
  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // This is called periodically
    // You can update the notification here
    FlutterForegroundTask.updateService(
      notificationTitle: 'Whisper Transcription',
      notificationText: _transcribedText.isNotEmpty ? _transcribedText : 'Listening...',
    );
    
    // Send transcribed text to the main UI
    sendPort?.send(_transcribedText);
  }
  
  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    print('WhisperTaskHandler: onDestroy');
    
    // Cancel timer
    _processingTimer?.cancel();
    
    // Stop recording
    await _recorder.stopRecorder();
    
    // Close recorder
    await _recorder.closeRecorder();
    
    // Cancel subscription
    await _recorderSubscription?.cancel();
    
    // Clean up resources
    print('WhisperTaskHandler: resources cleaned up');
  }
}
