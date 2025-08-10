import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/app_state.dart';
import '../widgets/status_indicator.dart';
import '../widgets/trigger_display.dart';
import '../widgets/connection_status.dart';
import '../services/voice_service.dart';
import '../services/camera_service.dart';
import '../services/communication_service.dart';
import '../services/shared_tts_service.dart';
import '../services/whisper_service_simple.dart';
import 'text_only_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late VoiceService _voiceService;
  late CameraService _cameraService;
  late CommunicationService _communicationService;
  late SharedTtsService _ttsService;
  late WhisperServiceSimple _whisperService;
  bool _isAutoListening = false;
  bool _isProcessing = false;
  bool _isWhisperInitialized = false;

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceService();
    _cameraService = CameraService();
    _communicationService = CommunicationService();
    _ttsService = SharedTtsService();
    _whisperService = WhisperServiceSimple();
    
    // Initialize services after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  void _initializeServices() async {
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    
    try {
      if (!mounted) return;
      appState.updateConnectionStatus('Initializing...', isConnected: false);
      if (!mounted) return;
      appState.setError('App Initializing...');
      appState.updateStatus(AppStatus.idle); // Start in idle state
      
      // Set up voice service callback for text recognition updates
      _voiceService.onTextRecognized = (text) {
        // This will trigger a rebuild of the UI when text is recognized
        if (mounted) {
          print('Voice service recognized text: $text');
          setState(() {
            // Just calling setState will rebuild the widget and update the text display
          });
          
          // Check for trigger word in speech-to-text mode
          if (!appState.isWhisperActive && text.toLowerCase().contains(_voiceService.triggerWord.toLowerCase())) {
            print('Trigger word detected in speech-to-text: ${_voiceService.triggerWord}');
            _processTriggerDetected();
          }
        }
      };
      
      // Initialize camera first
      if (!mounted) return;
      appState.setCameraStatus(false); // Camera initializing
      await _cameraService.initializeCamera();
      if (!mounted) return;
      appState.setCameraStatus(_cameraService.isCameraReady);
      
      if (!_cameraService.isCameraReady) {
        if (!mounted) return;
        appState.setError('Camera failed to initialize.');
        appState.updateStatus(AppStatus.error);
        return;
      } else {
        if (!mounted) return;
        appState.setError('Camera ready.');
      }
      
      // Initialize voice service
      await _voiceService.initialize();
      
      if (!mounted) return;
      if (!_voiceService.isInitialized) {
        if (!mounted) return;
        appState.setError('Voice service failed to initialize.');
        appState.updateStatus(AppStatus.error);
        return;
      } else {
        if (!mounted) return;
        appState.setError('Voice service ready.');
      }
      
      // Initialize Whisper service in the background
      try {
        await _whisperService.initialize();
        if (mounted) {
          setState(() {
            _isWhisperInitialized = true;
          });
          print('Whisper service initialized successfully');
        }
      } catch (e) {
        print('Whisper service initialization failed: $e');
        // Don't block the app if Whisper fails to initialize
        // Just continue with the default speech-to-text service
      }
      
      // Connect to RunPod service
      await _communicationService.connect();
      if (!mounted) return;
      if (_communicationService.isConnected) {
        if (!mounted) return;
        appState.updateConnectionStatus('Connected', isConnected: true);
        if (!mounted) return;
        appState.setError('Connected to RunPod.');
      } else {
        if (!mounted) return;
        appState.updateConnectionStatus('Connection Failed', isConnected: false);
        if (!mounted) return;
        appState.setError('RunPod connection failed.');
      }
      
      // Start automatic trigger word detection if voice service is ready
      if (!mounted) return;
      if (_voiceService.isInitialized) {
        // Add a small delay to ensure UI is updated before starting
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        _startAutomaticTriggerDetection();
      }
    } catch (e) {
      if (!mounted) return;
      appState.setError('Initialization failed: ${e.toString()}');
      if (!mounted) return;
      appState.updateConnectionStatus('Initialization Failed', isConnected: false);
      appState.updateStatus(AppStatus.error);
    }
  }

  void _startAutomaticTriggerDetection() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    _isAutoListening = true;
    appState.setError('Listening for "hey"...');
    appState.updateStatus(AppStatus.listening);
    
    try {
      // If Whisper is active and initialized, start continuous listening with Whisper
      if (appState.isWhisperActive && _isWhisperInitialized) {
        try {
          // Set up Whisper callback for text recognition updates
          _whisperService.onTextRecognized = (text) {
            if (mounted) {
              // Check for trigger word in the transcribed text
              if (text.toLowerCase().contains(_whisperService.triggerWord)) {
                _processTriggerDetected();
              }
            }
          };
          
          // Start continuous listening with Whisper
          await _whisperService.startContinuousListening();
        } catch (e) {
          print('Error starting Whisper continuous listening: $e');
          // Fall back to speech-to-text if Whisper fails
          appState.setTranscriptionMethod(TranscriptionMethod.speechToText);
          _startSpeechToTextListening(appState);
        }
      } else {
        // Use speech-to-text for trigger detection
        _startSpeechToTextListening(appState);
      }
    } catch (e) {
      appState.setError('Error in trigger detection: ${e.toString()}');
      appState.updateStatus(AppStatus.error);
      _isAutoListening = false;
    }
  }
  
  void _startSpeechToTextListening(AppState appState) async {
    try {
      print('Starting speech-to-text continuous listening...');
      appState.updateStatus(AppStatus.listening);
      
      // Use a simple loop that calls the same method as the test button
      _simpleContinuousListening();
      
      print('Speech-to-text continuous listening started');
    } catch (e) {
      print('Error starting speech-to-text continuous listening: $e');
      appState.setError('Error in trigger detection: ${e.toString()}');
      appState.updateStatus(AppStatus.error);
      _isAutoListening = false;
    }
  }

  /// Simple continuous listening that uses the same method as the test button
  void _simpleContinuousListening() async {
    print('Starting simple continuous listening loop...');
    
    while (_isAutoListening && mounted) {
      try {
        print('Starting new listening session (same as test button)...');
        
        // Use the exact same method as the test button
        final text = await _voiceService.listen();
        
        print('Simple continuous listening received text: $text');
        
        // Force UI update whenever we get text (even if empty)
        if (mounted) {
          setState(() {
            // This will trigger a rebuild and update the transcribed text display
          });
        }
        
        if (text.isNotEmpty) {
          print('Text detected: $text - stopping continuous effect');
          
          // Check for trigger word
          if (text.toLowerCase().contains(_voiceService.triggerWord.toLowerCase())) {
            print('Trigger word detected in simple continuous listening: ${_voiceService.triggerWord}');
            _processTriggerDetected();
            // Continue listening after processing
            await Future.delayed(const Duration(seconds: 2));
          }
          
          // Stop the continuous effect since we detected text
          // But keep listening for trigger words
          while (_isAutoListening && mounted && _voiceService.lastRecognizedText.isNotEmpty) {
            await Future.delayed(const Duration(seconds: 1));
            
            // Check if text was cleared or new trigger detected
            if (_voiceService.lastRecognizedText.isEmpty) {
              print('Text cleared - resuming continuous effect');
              break;
            }
          }
        } else {
          // No text detected - continue the continuous effect immediately
          print('No text detected - continuing continuous effect');
        }
        
        // Small delay before next listening session (only if no text detected)
        if (_isAutoListening && mounted && _voiceService.lastRecognizedText.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      } catch (e) {
        print('Error in simple continuous listening: $e');
        if (_isAutoListening && mounted) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
    
    print('Simple continuous listening loop ended');
  }

  Future<void> _processFullRequest() async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    final appState = Provider.of<AppState>(context, listen: false);
    final startTime = DateTime.now();
    
    try {
      appState.updateStatus(AppStatus.triggerDetected);
      appState.setError('Processing request...');
      
      // Listen for speech until "stop" is heard or 5 seconds timeout
      appState.updateStatus(AppStatus.listening);
      appState.setError('Listening until "stop" or 5 seconds...');
      
      String text = '';
      bool listeningCompleted = false;
      
      // Create a timeout future
      final timeoutFuture = Future.delayed(const Duration(seconds: 5));
      
      // Listen for speech
      final speechFuture = _voiceService.listenUntilStopWord();
      
      // Race between speech recognition and timeout
      await Future.any([speechFuture, timeoutFuture]).then((value) {
        if (value is String) {
          text = value;
          listeningCompleted = true;
        } else {
          // Timeout occurred - get the current transcribed text instead of error message
          text = _voiceService.lastRecognizedText.isNotEmpty 
            ? _voiceService.lastRecognizedText 
            : 'No speech detected';
          print('Timeout occurred, using transcribed text: $text');
        }
      });
      
      if (!listeningCompleted) {
        _voiceService.stopListening();
        // Ensure we get the latest transcribed text after stopping
        if (text == 'No speech detected' && _voiceService.lastRecognizedText.isNotEmpty) {
          text = _voiceService.lastRecognizedText;
          print('Updated text after stopping: $text');
        }
      }
      
      // Capture image
      appState.updateStatus(AppStatus.processing);
      appState.setError('Capturing image...');
      final imageFile = await _cameraService.captureImage();
      
      if (imageFile == null) {
        appState.setError('Failed to capture image: ${_cameraService.lastError}');
        appState.updateStatus(AppStatus.idle);
        _isProcessing = false;
        return;
      }
      
      // Send to RunPod if connected
      if (_communicationService.isConnected) {
        appState.updateStatus(AppStatus.dataSending);
        appState.setDataCommunicationStatus('Sending data...', dataInfo: 'Text: $text');
        appState.setError('Sending to RunPod...');
        
        try {
          final response = await _communicationService.sendRequest(text, imageFile);
          
          appState.updateStatus(AppStatus.dataSent);
          appState.setDataCommunicationStatus('Sent successfully', dataInfo: 'Text: $text');
          
          // Play response
          appState.updateStatus(AppStatus.speaking);
          appState.setError('Speaking response...');
          await _ttsService.speak(response);
        } catch (e) {
          appState.updateStatus(AppStatus.dataFailed);
          appState.setDataCommunicationStatus('Failed to send', dataInfo: 'Error: ${e.toString()}');
          appState.setError('Failed to send: ${e.toString()}');
        }
      } else {
        // Save locally if not connected
        appState.setError('Not connected. Saving locally...');
        await _saveDataLocally(imageFile, text);
        appState.setError('Data saved offline.');
        
        // Provide local feedback
        appState.updateStatus(AppStatus.speaking);
        await _ttsService.speak('I heard: $text. Data saved.');
      }
      
      // Calculate and display process duration
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      appState.setError('Ready. Process took ${duration.inSeconds} seconds.');
      
      appState.updateStatus(AppStatus.idle);
      
      // Reset data communication status after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          final currentState = Provider.of<AppState>(context, listen: false);
          if (currentState.status != AppStatus.dataSending && 
              currentState.status != AppStatus.dataSent && 
              currentState.status != AppStatus.speaking) {
            currentState.setDataCommunicationStatus('Not sent');
          }
        }
      });
    } catch (e) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.updateStatus(AppStatus.error);
      appState.setError('Error: ${e.toString()}');
    } finally {
      _isProcessing = false;
    }
  }

  void _saveOfflineData() async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    final appState = Provider.of<AppState>(context, listen: false);
    
    try {
      appState.updateStatus(AppStatus.listening);
      appState.setError('Listening until "stop"...');
      
      // Listen for user speech until "stop" is heard or timeout
      String text = '';
      bool listeningCompleted = false;
      
      // Create a timeout future
      final timeoutFuture = Future.delayed(const Duration(seconds: 5));
      
      // Listen for speech
      final speechFuture = _voiceService.listenUntilStopWord();
      
      // Race between speech recognition and timeout
      await Future.any([speechFuture, timeoutFuture]).then((value) {
        if (value is String) {
          text = value;
          listeningCompleted = true;
        } else {
          // Timeout occurred
          text = 'Timeout';
        }
      });
      
      if (!listeningCompleted) {
        _voiceService.stopListening();
      }
      
      appState.updateStatus(AppStatus.processing);
      appState.setError('Capturing image...');
      
      // Capture image
      final imageFile = await _cameraService.captureImage();
      
      if (imageFile == null) {
        appState.setError('Failed to capture image');
        appState.updateStatus(AppStatus.idle);
        _isProcessing = false;
        return;
      }
      
      // Save data locally
      await _saveDataLocally(imageFile, text);
      
      appState.updateStatus(AppStatus.idle);
      appState.setError('Data saved offline.');
    } catch (e) {
      appState.setError('Error: ${e.toString()}');
      appState.updateStatus(AppStatus.idle);
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _saveDataLocally(File imageFile, String text) async {
    try {
      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final offlineDir = Directory('${directory.path}/offline_data');
      
      // Create directory if it doesn't exist
      if (!await offlineDir.exists()) {
        await offlineDir.create(recursive: true);
      }
      
      // Create timestamp for unique filenames
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Save image
      final imageBytes = await imageFile.readAsBytes();
      final imageFilename = 'image_$timestamp.jpg';
      final imageSavePath = '${offlineDir.path}/$imageFilename';
      final imageSaveFile = File(imageSavePath);
      await imageSaveFile.writeAsBytes(imageBytes);
      
      // Save text
      final textFilename = 'text_$timestamp.txt';
      final textSavePath = '${offlineDir.path}/$textFilename';
      final textSaveFile = File(textSavePath);
      await textSaveFile.writeAsString(text);
      
      // Create metadata file
      final metadataFilename = 'metadata_$timestamp.json';
      final metadataSavePath = '${offlineDir.path}/$metadataFilename';
      final metadataSaveFile = File(metadataSavePath);
      await metadataSaveFile.writeAsString('''
{
  "timestamp": $timestamp,
  "image_file": "$imageFilename",
  "text_file": "$textFilename",
  "text_content": "$text"
}
''');
    } catch (e) {
      throw Exception('Failed to save data locally: $e');
    }
  }

  void _testConnection() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    try {
      appState.updateConnectionStatus('Testing...', isConnected: false);
      appState.setError('Testing connection...');
      
      // Test connection to RunPod service
      await _communicationService.connect();
      
      appState.updateConnectionStatus('Connected', isConnected: true);
      appState.setError('Connection successful!');
    } catch (e) {
      appState.updateConnectionStatus('Connection Failed', isConnected: false);
      appState.setError('Connection failed: ${e.toString()}');
    }
  }

  void _showSavedDataFolder() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final offlineDir = Directory('${directory.path}/offline_data');
      
      if (await offlineDir.exists()) {
        final appState = Provider.of<AppState>(context, listen: false);
        appState.setError('Folder: ${offlineDir.path}');
      } else {
        final appState = Provider.of<AppState>(context, listen: false);
        appState.setError('No offline data folder found');
      }
    } catch (e) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.setError('Error: $e');
    }
  }

  void _processTriggerDetected() async {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.updateStatus(AppStatus.triggerDetected);
    appState.setTriggerDetected('hey');
    appState.setError('Trigger detected! Processing...');
    
    // Automatically process the request
    await _processFullRequest();
    
    // Reset trigger display after processing
    await Future.delayed(const Duration(seconds: 2));
    appState.setTriggerDetected('');
    appState.setError('Ready. Listening for "hey"...');
    appState.updateStatus(AppStatus.listening); // Go back to listening state
  }

  void _stopAutomaticListening() {
    _isAutoListening = false;
    
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Stop the appropriate service based on the current transcription method
    if (appState.isWhisperActive && _isWhisperInitialized) {
      _whisperService.stopListening();
    } else {
      _voiceService.stopListening();
    }
    
    appState.setMicrophoneActive(false);
    appState.setError('Listening stopped');
  }
  
  void _startAutomaticListening() {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Check if the appropriate service is initialized
    if ((appState.isWhisperActive && _isWhisperInitialized) || 
        (!appState.isWhisperActive && _voiceService.isInitialized)) {
      appState.setMicrophoneActive(true);
      _startAutomaticTriggerDetection();
    } else {
      if (appState.isWhisperActive && !_isWhisperInitialized) {
        appState.setError('Whisper service not initialized. Switching to speech-to-text.');
        appState.setTranscriptionMethod(TranscriptionMethod.speechToText);
        // Try again with speech-to-text
        _startAutomaticListening();
      } else {
        appState.setError('Voice service not initialized. Please reset the app.');
      }
    }
  }
  
  void _toggleTranscriptionMethod() {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Stop current listening
    if (_isAutoListening) {
      _stopAutomaticListening();
    }
    
    // Toggle transcription method
    appState.toggleTranscriptionMethod();
    
    // Show appropriate message
    if (appState.isWhisperActive) {
      if (_isWhisperInitialized) {
        appState.setError('Switched to Whisper transcription');
      } else {
        appState.setError('Whisper not initialized. Initializing...');
        // Try to initialize Whisper
        _whisperService.initialize().then((_) {
          setState(() {
            _isWhisperInitialized = true;
          });
          appState.setError('Whisper initialized successfully');
        }).catchError((e) {
          appState.setError('Failed to initialize Whisper: $e');
          // Switch back to speech-to-text
          appState.setTranscriptionMethod(TranscriptionMethod.speechToText);
        });
      }
    } else {
      appState.setError('Switched to speech-to-text transcription');
    }
    
    // Restart listening if it was active
    if (appState.isMicrophoneActive) {
      _startAutomaticListening();
    }
  }
  
  void _resetApp() {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Reset all states
    appState.updateStatus(AppStatus.idle);
    appState.setTriggerDetected('');
    appState.setDataCommunicationStatus('Not sent');
    appState.setMicrophoneActive(false);
    appState.setTextOnlyMode(false);
    appState.clearError();
    
    // Stop any ongoing processes
    _isProcessing = false;
    _isAutoListening = false;
    _voiceService.stopListening();
    
    // Restart automatic listening
    if (_voiceService.isInitialized) {
      _startAutomaticListening();
    } else {
      appState.setError('App reset. Voice service not initialized.');
    }
  }

  void _testTranscription() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    try {
      appState.setError('Testing transcription... Speak now.');
      appState.updateStatus(AppStatus.listening);
      
      // Listen for speech for a short duration
      final text = await _voiceService.listen();
      
      if (text.isNotEmpty) {
        appState.setError('Transcription test complete.');
      } else {
        appState.setError('No speech detected during test.');
      }
      
      // Reset to idle after a short delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          final currentState = Provider.of<AppState>(context, listen: false);
          if (currentState.status == AppStatus.listening) {
            currentState.updateStatus(AppStatus.idle);
            currentState.setError('Ready.');
          }
        }
      });
    } catch (e) {
      appState.setError('Transcription test failed: ${e.toString()}');
      appState.updateStatus(AppStatus.error);
    }
  }

  @override
  void dispose() {
    // Dispose resources
    _whisperService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TalkToApp'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Status Indicator
                const StatusIndicator(),
                const SizedBox(height: 20),
                
                // Trigger Display
                const TriggerDisplay(),
                const SizedBox(height: 20),
                
                // Connection Status
                const ConnectionStatus(),
                const SizedBox(height: 20),
                
                // Process Visualization
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Process Status:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildProcessStep('🎤 Trigger Detected', appState.triggerDetected.isNotEmpty, 'Listening for "hey"'),
                      const SizedBox(height: 4),
                      _buildProcessStep('🗣️ Speech to Text', appState.status == AppStatus.listening && appState.triggerDetected.isNotEmpty, 'Converting speech to text'),
                      const SizedBox(height: 4),
                      _buildProcessStep('📸 Image Capture', appState.status == AppStatus.processing, 'Taking picture'),
                      const SizedBox(height: 4),
                      _buildProcessStep('📡 Data Communication', 
                        appState.status == AppStatus.dataSending || 
                        appState.status == AppStatus.dataSent || 
                        appState.dataCommunicationStatus.contains('Sending') || 
                        appState.dataCommunicationStatus.contains('Sent'), 
                        'Communicating with RunPod'),
                      const SizedBox(height: 4),
                      _buildProcessStep('📥 Response Received', 
                        appState.status == AppStatus.speaking || 
                        appState.status == AppStatus.dataSent || 
                        appState.dataCommunicationStatus.contains('Sent'), 
                        'Response from AI model'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Transcribed Text Display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transcribed Text:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        // Show text from either voice service or whisper service based on active transcription method
                        appState.isWhisperActive 
                          ? (_whisperService.lastRecognizedText.isEmpty 
                              ? 'No speech detected yet (Whisper)' 
                              : _whisperService.lastRecognizedText)
                          : (_voiceService.lastRecognizedText.isEmpty 
                              ? 'No speech detected yet (Speech-to-Text)' 
                              : _voiceService.lastRecognizedText),
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Test Transcription Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _testTranscription(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Test Transcription',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Action Buttons - All visible and properly spaced
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _processFullRequest(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Manual Process Request',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _testConnection(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Test Connection',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _saveOfflineData(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save Offline Data',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showSavedDataFolder(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Show Saved Data Folder',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _resetApp(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Reset App',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Microphone Button with Icon
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      _isAutoListening ? Icons.mic : Icons.mic_off,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _isAutoListening ? () => _stopAutomaticListening() : () => _startAutomaticListening(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAutoListening ? Colors.red : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    label: Text(
                      _isAutoListening ? 'Microphone Active - Tap to Deactivate' : 'Microphone Inactive - Tap to Activate',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Transcription Method Toggle Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      appState.isWhisperActive ? Icons.record_voice_over : Icons.keyboard_voice,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => _toggleTranscriptionMethod(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appState.isWhisperActive ? Colors.purple : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    label: Text(
                      appState.isWhisperActive 
                        ? 'Using Whisper - Tap to Switch to Speech-to-Text' 
                        : 'Using Speech-to-Text - Tap to Switch to Whisper',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Text Only Mode Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.text_fields,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      // Set text-only mode to true
                      final appState = Provider.of<AppState>(context, listen: false);
                      appState.setTextOnlyMode(true);
                      
                      // Navigate to text-only screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TextOnlyScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    label: const Text(
                      'Text Only Mode',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                
                // Test Simple Whisper Implementation Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.mic_external_on,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      // Navigate to the simple Whisper test screen
                      Navigator.pushNamed(context, '/test_whisper_simple');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    label: const Text(
                      'Test Simple Whisper Implementation',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Data Communication Status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: appState.dataCommunicationStatus.contains('Sent') 
                      ? Colors.green[100] 
                      : appState.dataCommunicationStatus.contains('Failed') 
                        ? Colors.red[100] 
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Status: ${appState.dataCommunicationStatus}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (appState.lastDataSent.isNotEmpty)
                        Text(
                          'Last data: ${appState.lastDataSent}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      if (appState.lastDataSentTime != null)
                        Text(
                          'Sent at: ${appState.lastDataSentTime!.toLocal()}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Error Display
                if (appState.errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      appState.errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // Status Information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App Status: ${appState.status.toString().split('.').last}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Auto Listening: ${_isAutoListening ? "ON" : "OFF"}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Camera Ready: ${_cameraService.isCameraReady ? "YES" : "NO"}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Voice Service: ${_voiceService.isInitialized ? "READY" : "INITIALIZING"}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Whisper Service: ${_isWhisperInitialized ? "READY" : "INITIALIZING"}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Transcription Method: ${appState.isWhisperActive ? "WHISPER" : "SPEECH-TO-TEXT"}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProcessStep(String title, bool isActive, String description) {
    return Row(
      children: [
        Icon(
          isActive ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isActive ? Colors.green : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.green : Colors.grey[700],
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
