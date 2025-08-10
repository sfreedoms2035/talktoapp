import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart' show rootBundle, BackgroundIsolateBinaryMessenger;
import 'package:flutter/foundation.dart';

/// A simplified service that provides speech recognition using the Whisper model.
/// This version doesn't use the foreground service for testing purposes.
class WhisperServiceSimple {
  // Whisper model instance
  late final Whisper _whisper;
  
  // Flutter Sound recorder for audio capture
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  
  // Stream subscription for audio data
  StreamSubscription? _recorderSubscription;
  
  // Buffer for audio data with fixed capacity to prevent memory leaks
  final List<int> _audioBuffer = [];
  
  // Maximum buffer size to prevent memory leaks (5 seconds of audio)
  static const int MAX_BUFFER_SIZE = 160000; // 5 seconds of 16kHz 16-bit audio
  
  // Isolate for background processing
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  
  // State variables
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isModelLoaded = false;
  String _lastRecognizedText = '';
  
  // Callback for text recognition updates
  Function(String)? onTextRecognized;
  
  // Timer for processing audio buffer
  Timer? _processingTimer;
  
  // Processing flag
  bool _isProcessing = false;
  
  // Constants
  static const String TRIGGER_WORD = 'hey';
  static const String STOP_WORD = 'stop';
  
  // Buffer size constants (in seconds of audio at 16kHz, 16-bit)
  static const double BUFFER_SIZE_SECONDS = 1.0; // Reduced from 2 seconds to 1 second for faster response
  static const int SAMPLE_RATE = 16000;
  static const int BYTES_PER_SAMPLE = 2; // 16-bit audio = 2 bytes per sample
  static const int BUFFER_THRESHOLD = 32000; // 1 second of 16kHz 16-bit audio (16000 * 2 * 1)
  
  /// Get the path to the model file by copying it from assets to a writable directory
  Future<String> _getModelPath(String assetPath) async {
    print('Getting model path for asset: $assetPath');
    
    // Extract the filename from the asset path
    final filename = assetPath.split('/').last;
    
    // Get the application documents directory
    final directory = await getApplicationDocumentsDirectory();
    final modelPath = '${directory.path}/$filename';
    
    print('Target model path: $modelPath');
    
    // Check if the model is already in the documents directory
    final file = File(modelPath);
    if (await file.exists()) {
      print('Model file already exists in documents directory');
      return modelPath;
    }
    
    print('Copying model from assets to documents directory...');
    
    try {
      // Load the model data from assets
      final modelData = await rootBundle.load(assetPath);
      final buffer = modelData.buffer;
      
      // Write the model data to the documents directory
      await file.writeAsBytes(
        buffer.asUint8List(modelData.offsetInBytes, modelData.lengthInBytes),
      );
      
      print('Model copied successfully to: $modelPath');
      return modelPath;
    } catch (e) {
      print('Error copying model from assets: $e');
      throw Exception('Failed to copy model from assets: $e');
    }
  }
  
  /// Initialize the service
  Future<void> initialize() async {
    try {
      print('Initializing Whisper service (simple version)...');
      
      // Initialize the isolate for background processing
      await _initializeIsolate();
      
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
      
      // Initialize Whisper with the tiny model for better performance
      print('Loading Whisper tiny model...');
      try {
        // Use the tiny model for faster processing
        _whisper = Whisper(model: WhisperModel.tiny);
        
        _isModelLoaded = true;
        print('Whisper tiny model loaded successfully');
      } catch (e) {
        print('Error loading Whisper tiny model: $e');
        
        // Try with base model as fallback
        try {
          print('Trying built-in base model as fallback...');
          _whisper = Whisper(model: WhisperModel.base);
          _isModelLoaded = true;
          print('Whisper base model loaded as fallback');
        } catch (e) {
          print('Error initializing Whisper base model: $e');
          throw Exception('Failed to initialize Whisper: $e');
        }
      }
      
      _isInitialized = true;
      print('Whisper service (simple version) initialized');
    } catch (e) {
      print('Error initializing Whisper service: $e');
      _isInitialized = false;
      throw Exception('Failed to initialize Whisper service: $e');
    }
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
      print('Starting continuous listening with Whisper (simple version)...');
      _isRecording = true;
      _lastRecognizedText = '';
      
      // Start recording
      await _startRecording();
      
      print('Continuous listening started');
    } catch (e) {
      print('Error starting continuous listening: $e');
      _isRecording = false;
      throw Exception('Failed to start continuous listening: $e');
    }
  }
  
  /// Start recording audio
  Future<void> _startRecording() async {
    try {
      print('Starting recording...');
      
      // Create a stream controller for audio data
      final StreamController<Uint8List> recordingDataController = StreamController<Uint8List>();
      
      // Listen to the audio stream
      _recorderSubscription = recordingDataController.stream.listen((buffer) {
        _processAudioBuffer(buffer);
      }, onError: (error) {
        print('Error in audio stream: $error');
        if (onTextRecognized != null) {
          onTextRecognized!("Error in audio stream: $error");
        }
      });
      
      // Start recording
      await _recorder.startRecorder(
        toStream: recordingDataController.sink,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 16000,
      );
      
      // Start a timer to periodically process the audio buffer (even more frequent processing)
      _processingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (_audioBuffer.isNotEmpty && !_isProcessing) {
          _transcribeBufferAsync();
        }
      });
      
      print('Recording started');
    } catch (e) {
      print('Error starting recording: $e');
      throw Exception('Failed to start recording: $e');
    }
  }
  
  /// Process audio buffer with improved memory management
  void _processAudioBuffer(Uint8List buffer) {
    // Add data to buffer with size limit to prevent memory leaks
    _audioBuffer.addAll(buffer);
    
    // Enforce maximum buffer size to prevent memory leaks
    if (_audioBuffer.length > MAX_BUFFER_SIZE) {
      print('WARNING: Audio buffer exceeded maximum size (${MAX_BUFFER_SIZE} bytes), trimming oldest data');
      // Remove oldest data to keep buffer size under limit
      _audioBuffer.removeRange(0, _audioBuffer.length - MAX_BUFFER_SIZE);
    }
    
    // Only log occasionally to reduce overhead
    if (_audioBuffer.length % 8000 == 0) {
      print('Audio buffer size: ${_audioBuffer.length} bytes');
    }
    
    // When buffer reaches the threshold size
    if (_audioBuffer.length > BUFFER_THRESHOLD && !_isProcessing) {
      print('Buffer reached threshold size (${BUFFER_THRESHOLD} bytes, ${BUFFER_SIZE_SECONDS} seconds), starting transcription...');
      _transcribeBufferAsync();
    }
  }
  
  /// Transcribe buffer asynchronously
  Future<void> _transcribeBufferAsync() async {
    if (_isProcessing) {
      print('Already processing audio, skipping this buffer');
      return;
    }
    
    print('Starting async transcription process');
    _isProcessing = true;
    
    // Make a copy of the buffer and clear it
    final List<int> bufferCopy = List.from(_audioBuffer);
    print('Copied buffer size: ${bufferCopy.length} bytes');
    _audioBuffer.clear();
    
    // Process in a separate async function to not block the audio stream
    try {
      await _transcribeBuffer(bufferCopy);
      print('Transcription completed successfully');
    } catch (e, stackTrace) {
      print('Error in async transcription: $e');
      print('Stack trace: $stackTrace');
      if (onTextRecognized != null) {
        onTextRecognized!("Error in transcription: $e");
      }
    } finally {
      _isProcessing = false;
      print('Transcription process finished, ready for next buffer');
    }
  }
  
  /// Transcribe buffer using isolate for background processing
  Future<void> _transcribeBuffer(List<int> buffer) async {
    try {
      print('Starting transcription of buffer with size: ${buffer.length} bytes');
      
      // Check if isolate is initialized
      if (_sendPort == null) {
        print('WARNING: Isolate not initialized, falling back to main thread transcription');
        await _transcribeBufferInMainThread(buffer);
        return;
      }
      
      // Write buffer to temporary WAV file
      final tempPath = await _writeBufferToTempFile(buffer);
      print('Wrote buffer to temporary WAV file: $tempPath');
      
      // Verify the file exists and has content
      final file = File(tempPath);
      if (!file.existsSync()) {
        print('ERROR: Temporary file does not exist: $tempPath');
        throw Exception('Temporary file does not exist');
      }
      
      final fileSize = await file.length();
      print('Temporary file size: $fileSize bytes');
      
      if (fileSize <= 44) { // WAV header is 44 bytes
        print('ERROR: Temporary file contains only header, no audio data');
        throw Exception('No audio data in temporary file');
      }
      
      print('Sending audio file path to isolate for transcription: $tempPath');
      
      // Send the audio file path to the isolate for transcription
      _sendPort!.send({'audio_path': tempPath});
      
      // Note: The isolate will handle the transcription and send the result back
      // The result will be received in the _initializeIsolate method's listener
      
      // The isolate will delete the temporary file after transcription
    } catch (e, stackTrace) {
      print('ERROR transcribing buffer: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to transcribe audio: $e');
    }
  }
  
  /// Fallback method to transcribe buffer in the main thread if isolate is not available
  Future<void> _transcribeBufferInMainThread(List<int> buffer) async {
    try {
      print('Starting transcription in main thread as fallback');
      
      // Write buffer to temporary WAV file
      final tempPath = await _writeBufferToTempFile(buffer);
      print('Wrote buffer to temporary WAV file: $tempPath');
      
      // Verify the file exists and has content
      final file = File(tempPath);
      if (!file.existsSync()) {
        print('ERROR: Temporary file does not exist: $tempPath');
        throw Exception('Temporary file does not exist');
      }
      
      final fileSize = await file.length();
      print('Temporary file size: $fileSize bytes');
      
      if (fileSize <= 44) { // WAV header is 44 bytes
        print('ERROR: Temporary file contains only header, no audio data');
        throw Exception('No audio data in temporary file');
      }
      
      print('Starting Whisper transcription in main thread...');
      // Transcribe the file with optimized parameters for minimal latency
      final result = await _whisper.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: tempPath,
          isTranslate: false,
          isNoTimestamps: true,
          splitOnWord: false,
          // Add additional parameters to improve performance and accuracy
          language: 'en',    // Specify English language for better accuracy
          speedUp: true,     // Enable speed-up for faster processing
        ),
      );
      
      print('Whisper transcription completed, result: $result');
      
      // Update transcribed text
      if (result != null && result.text != null && result.text!.isNotEmpty) {
        _lastRecognizedText = result.text!;
        
        print('Transcribed text: $_lastRecognizedText');
        
        // Call the callback with additional debug info
        if (onTextRecognized != null) {
          print('Calling onTextRecognized callback with text: $_lastRecognizedText');
          print('Callback function is not null, calling it now...');
          try {
            onTextRecognized!(_lastRecognizedText);
            print('Callback called successfully');
          } catch (e) {
            print('ERROR calling callback: $e');
          }
        } else {
          print('WARNING: onTextRecognized callback is null');
        }
        
        // Check for trigger word
        if (_lastRecognizedText.toLowerCase().contains(TRIGGER_WORD.toLowerCase())) {
          print('Trigger word detected: $TRIGGER_WORD');
        }
        
        // Check for stop word
        if (_lastRecognizedText.toLowerCase().contains(STOP_WORD.toLowerCase())) {
          print('Stop word detected: $STOP_WORD');
        }
      } else {
        print('WARNING: No text in transcription result or result is null');
        print('Result object: $result');
        if (result != null) {
          print('Result text: ${result.text}');
        }
        
        // Still call the callback to indicate no speech was detected
        if (onTextRecognized != null) {
          print('Calling callback with "No speech detected" message');
          onTextRecognized!("No speech detected");
        }
      }
      
      // Delete temporary file
      print('Deleting temporary file: $tempPath');
      File(tempPath).deleteSync();
    } catch (e, stackTrace) {
      print('ERROR transcribing buffer in main thread: $e');
      print('Stack trace: $stackTrace');
      
      // Call the callback with error message
      if (onTextRecognized != null) {
        onTextRecognized!("Error in transcription: $e");
      }
      
      throw Exception('Failed to transcribe audio in main thread: $e');
    }
  }
  
  /// Write buffer to temporary WAV file
  Future<String> _writeBufferToTempFile(List<int> buffer) async {
    try {
      print('Writing buffer to temporary WAV file, buffer size: ${buffer.length} bytes');
      
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      print('Temporary directory: ${tempDir.path}');
      final tempPath = '${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
      print('Temporary file path: $tempPath');
      
      // Create WAV file
      final file = File(tempPath);
      print('Creating file...');
      final sink = file.openWrite();
      
      // Write WAV header
      final header = _createWavHeader(buffer.length);
      print('Created WAV header, size: ${header.length} bytes');
      sink.add(header);
      
      // Write audio data
      print('Writing audio data...');
      sink.add(buffer);
      
      // Close file
      print('Closing file...');
      await sink.close();
      
      // Verify file was created and has the expected size
      if (file.existsSync()) {
        final fileSize = await file.length();
        print('File created successfully, size: $fileSize bytes');
        if (fileSize != buffer.length + 44) { // 44 bytes for WAV header
          print('WARNING: File size does not match expected size. Expected: ${buffer.length + 44}, Actual: $fileSize');
        }
      } else {
        print('ERROR: File was not created');
        throw Exception('File was not created');
      }
      
      return tempPath;
    } catch (e, stackTrace) {
      print('ERROR writing buffer to temp file: $e');
      print('Stack trace: $stackTrace');
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
  
  /// Stop listening
  Future<void> stopListening() async {
    if (!_isRecording) {
      return;
    }
    
    try {
      print('Stopping Whisper listening (simple version)...');
      
      // Set recording flag to false
      _isRecording = false;
      
      // Cancel timer
      _processingTimer?.cancel();
      
      // Stop recording
      await _recorder.stopRecorder();
      
      // Cancel subscription
      await _recorderSubscription?.cancel();
      
      print('Whisper listening stopped');
    } catch (e) {
      print('Error stopping Whisper listening: $e');
    }
  }
  
  /// Initialize the isolate for background processing
  Future<void> _initializeIsolate() async {
    print('Isolate functionality temporarily disabled due to Flutter plugin compatibility issues');
    print('Using main thread transcription for now');
    
    // Temporarily disable isolate functionality due to Flutter plugin issues
    // The Whisper plugin doesn't work properly in isolates even with BackgroundIsolateBinaryMessenger
    // We'll use main thread transcription as a fallback for now
    
    // TODO: Investigate alternative approaches for background processing:
    // 1. Use compute() function for CPU-intensive tasks
    // 2. Implement native platform channels for background processing
    // 3. Use a different speech recognition library that supports isolates
    
    _sendPort = null; // Ensure isolate is marked as not initialized
  }
  
  /// Isolate entry point for background processing
  static void _isolateEntryPoint(SendPort sendPort) async {
    // Create a receive port for communication with the main isolate
    final receivePort = ReceivePort();
    
    // Send the send port to the main isolate
    sendPort.send(receivePort.sendPort);
    
    // Initialize the background isolate binary messenger
    try {
      BackgroundIsolateBinaryMessenger.ensureInitialized(RootIsolateToken.instance!);
      print('Background isolate binary messenger initialized');
    } catch (e) {
      print('Error initializing background isolate binary messenger: $e');
      sendPort.send({'error': 'Failed to initialize background isolate binary messenger: $e'});
      return;
    }
    
    // Initialize Whisper in the isolate
    Whisper? whisper;
    try {
      whisper = Whisper(model: WhisperModel.tiny);
      print('Whisper initialized in isolate');
    } catch (e) {
      print('Error initializing Whisper in isolate: $e');
      try {
        whisper = Whisper(model: WhisperModel.base);
        print('Whisper base model initialized in isolate as fallback');
      } catch (e) {
        print('Error initializing Whisper base model in isolate: $e');
        sendPort.send({'error': 'Failed to initialize Whisper in isolate: $e'});
        return;
      }
    }
    
    // Listen for messages from the main isolate
    receivePort.listen((message) async {
      if (message is Map<String, dynamic> && message.containsKey('audio_path')) {
        final audioPath = message['audio_path'] as String;
        
        try {
          // Transcribe the audio file
          final result = await whisper?.transcribe(
            transcribeRequest: TranscribeRequest(
              audio: audioPath,
              isTranslate: false,
              isNoTimestamps: true,
              splitOnWord: false,
              language: 'en',
              speedUp: true,
            ),
          );
          
          if (result != null && result.text != null && result.text!.isNotEmpty) {
            // Send the transcription result back to the main isolate
            sendPort.send({'transcription': result.text!});
          } else {
            sendPort.send({'transcription': 'No speech detected'});
          }
          
          // Delete the temporary file
          try {
            File(audioPath).deleteSync();
          } catch (e) {
            print('Error deleting temporary file in isolate: $e');
          }
        } catch (e) {
          sendPort.send({'error': 'Error transcribing audio in isolate: $e'});
        }
      }
    });
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await stopListening();
    await _recorder.closeRecorder();
    
    // Terminate the isolate
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    _isolate = null;
    _receivePort = null;
    _sendPort = null;
  }
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;
  bool get isModelLoaded => _isModelLoaded;
  String get lastRecognizedText => _lastRecognizedText;
  String get triggerWord => TRIGGER_WORD;
}
