import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/app_state.dart';
import '../widgets/status_indicator.dart';
import '../widgets/connection_status.dart';
import '../services/camera_service.dart';
import '../services/communication_service.dart';
import '../services/shared_tts_service.dart';

class TextOnlyScreen extends StatefulWidget {
  const TextOnlyScreen({super.key});

  @override
  State<TextOnlyScreen> createState() => _TextOnlyScreenState();
}

class _TextOnlyScreenState extends State<TextOnlyScreen> {
  late CameraService _cameraService;
  late CommunicationService _communicationService;
  late SharedTtsService _ttsService;
  bool _isProcessing = false;
  final TextEditingController _textController = TextEditingController();

  // Default text options
  final List<String> _defaultTexts = [
    "What do you see exactly in the picture",
    "Describe the nearest object",
    "What could happen next",
    "Describe the colors of the objects you are seeing"
  ];

  @override
  void initState() {
    super.initState();
    _cameraService = CameraService();
    _communicationService = CommunicationService();
    _ttsService = SharedTtsService();
    
    // Initialize services after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }
  
  void _initializeServices() async {
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    
    try {
      // Initialize camera first
      appState.setCameraStatus(false); // Camera initializing
      appState.setError('Initializing camera...');
      await _cameraService.initializeCamera();
      
      if (!mounted) return;
      appState.setCameraStatus(_cameraService.isCameraReady);
      
      if (!_cameraService.isCameraReady) {
        appState.setError('Camera failed to initialize.');
        return;
      } else {
        appState.setError('Camera ready.');
      }
      
      // Connect to RunPod service
      appState.updateConnectionStatus('Connecting...', isConnected: false);
      await _communicationService.connect();
      
      if (!mounted) return;
      if (_communicationService.isConnected) {
        appState.updateConnectionStatus('Connected', isConnected: true);
        appState.setError('Connected to RunPod.');
      } else {
        appState.updateConnectionStatus('Connection Failed', isConnected: false);
        appState.setError('RunPod connection failed: ${_communicationService.lastError}');
      }
    } catch (e) {
      if (!mounted) return;
      appState.setError('Initialization failed: ${e.toString()}');
      appState.updateConnectionStatus('Initialization Failed', isConnected: false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _cameraService.dispose(); // Dispose camera when leaving the screen
    super.dispose();
  }

  Future<void> _processWithText(String text) async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    final appState = Provider.of<AppState>(context, listen: false);
    final startTime = DateTime.now();
    
    try {
      appState.updateStatus(AppStatus.processing);
      appState.setError('Processing with text: "$text"');
      
      // Check if camera is initialized
      if (!_cameraService.isInitialized) {
        appState.setError('Camera not initialized. Initializing...');
        await _cameraService.initializeCamera();
        
        if (!_cameraService.isCameraReady) {
          appState.setError('Failed to initialize camera: ${_cameraService.lastError}');
          appState.updateStatus(AppStatus.error);
          _isProcessing = false;
          return;
        }
      }
      
      // Capture image
      appState.setError('Capturing image...');
      final imageFile = await _cameraService.captureImage();
      
      if (imageFile == null) {
        appState.setError('Failed to capture image: ${_cameraService.lastError}');
        appState.updateStatus(AppStatus.idle);
        _isProcessing = false;
        return;
      }
      
      // Check connection and reconnect if needed
      if (!_communicationService.isConnected) {
        appState.setError('Not connected to RunPod. Attempting to connect...');
        await _communicationService.connect();
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
        await _ttsService.speak('Text saved: $text. Data saved offline.');
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
  "text_content": "$text",
  "mode": "text_only"
}
''');
    } catch (e) {
      throw Exception('Failed to save data locally: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Only Mode'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Set text-only mode to false when navigating back
            final appState = Provider.of<AppState>(context, listen: false);
            appState.setTextOnlyMode(false);
            Navigator.pop(context);
          },
        ),
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
                
                // Connection Status
                const ConnectionStatus(),
                const SizedBox(height: 20),
                
                // Default Text Options
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.indigo[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Default Text Options:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._defaultTexts.map((text) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ElevatedButton(
                          onPressed: () => _processWithText(text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            alignment: Alignment.centerLeft,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            text,
                            style: const TextStyle(fontSize: 14),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      )).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Custom Text Input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Custom Text:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Enter your custom text...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_textController.text.trim().isNotEmpty) {
                              _processWithText(_textController.text.trim());
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter some text'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Send',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
