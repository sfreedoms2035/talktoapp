import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../widgets/status_indicator.dart';
import '../widgets/trigger_display.dart';
import '../widgets/connection_status.dart';
import '../services/voice_service.dart';
import '../services/camera_service.dart';
import '../services/communication_service.dart';
import '../services/tts_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late VoiceService _voiceService;
  late CameraService _cameraService;
  late CommunicationService _communicationService;
  late TtsService _ttsService;

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceService();
    _cameraService = CameraService();
    _communicationService = CommunicationService();
    _ttsService = TtsService();
    
    // Initialize services
    _initializeServices();
  }

  void _initializeServices() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    try {
      appState.updateConnectionStatus('Connecting...', isConnected: false);
      
      // Initialize camera
      await _cameraService.initializeCamera();
      
      // Initialize voice service
      await _voiceService.initialize();
      
      // Connect to RunPod service
      await _communicationService.connect();
      
      appState.updateConnectionStatus('Connected', isConnected: true);
    } catch (e) {
      appState.setError('Failed to initialize services: ${e.toString()}');
    }
  }

  void _onTriggerDetected() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    try {
      appState.setTriggerDetected('Hey monitor');
      appState.updateStatus(AppStatus.processing);
      
      // Capture image
      final imageFile = await _cameraService.captureImage();
      
      if (imageFile == null) {
        appState.setError('Failed to capture image');
        return;
      }
      
      appState.updateStatus(AppStatus.listening);
      
      // Listen for user command
      final text = await _voiceService.listen();
      
      if (text.isEmpty) {
        appState.setError('No speech detected');
        return;
      }
      
      appState.updateStatus(AppStatus.sending);
      
      // Send to RunPod
      final response = await _communicationService.sendRequest(text, imageFile);
      
      appState.updateStatus(AppStatus.receiving);
      
      // Play response
      appState.updateStatus(AppStatus.speaking);
      await _ttsService.speak(response);
      
      appState.updateStatus(AppStatus.idle);
      appState.setTriggerDetected('');
    } catch (e) {
      appState.setError('Error processing request: ${e.toString()}');
    }
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
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Status Indicator
                const StatusIndicator(),
                const SizedBox(height: 30),
                
                // Trigger Display
                const TriggerDisplay(),
                const SizedBox(height: 30),
                
                // Connection Status
                const ConnectionStatus(),
                const SizedBox(height: 30),
                
                // Action Buttons
                ElevatedButton(
                  onPressed: appState.status == AppStatus.idle 
                      ? () => _onTriggerDetected() 
                      : null,
                  child: const Text('Simulate Trigger'),
                ),
                
                const SizedBox(height: 20),
                
                // Error Display
                if (appState.errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.red[100],
                    child: Text(
                      appState.errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                
                const Spacer(),
                
                // Status Text
                Text(
                  'Status: ${appState.status.toString().split('.').last}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
