import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCameraReady = false;
  String _lastError = '';

  Future<void> initializeCamera() async {
    try {
      print('Initializing camera...');
      _lastError = '';
      
      _cameras = await availableCameras();
      print('Found ${_cameras.length} cameras');
      
      // Find the rear camera (usually the first one or the one with direction back)
      CameraDescription? rearCamera;
      for (var camera in _cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          rearCamera = camera;
          print('Found rear camera: ${camera.name}');
          break;
        }
      }
      
      // If no rear camera found, use the first camera
      rearCamera ??= _cameras.isNotEmpty ? _cameras.first : null;
      print('Using camera: ${rearCamera?.name ?? "none"}');
      
      if (rearCamera == null) {
        _lastError = 'No camera found';
        _isInitialized = false;
        _isCameraReady = false;
        return;
      }
      
      _controller = CameraController(
        rearCamera,
        ResolutionPreset.medium, // Use medium resolution for balance between quality and performance
        enableAudio: false, // We don't need audio for image capture
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      print('Initializing camera controller...');
      await _controller!.initialize();
      _isInitialized = true;
      _isCameraReady = true;
      print('Camera initialized successfully');
    } catch (e) {
      _lastError = 'Error initializing camera: $e';
      print(_lastError);
      _isInitialized = false;
      _isCameraReady = false;
    }
  }

  Future<File?> captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      final error = 'Camera not initialized. Initialized: $_isInitialized, Controller: ${_controller != null}';
      print(error);
      throw Exception(error);
    }
    
    if (!_controller!.value.isTakingPicture) {
      try {
        print('Capturing image...');
        // Take the picture
        final XFile picture = await _controller!.takePicture();
        print('Image captured: ${picture.path}');
        
        // Get the temporary directory
        final tempDir = await getTemporaryDirectory();
        print('Temporary directory: ${tempDir.path}');
        
        // Create a new file path
        final fileName = path.basename(picture.path);
        final newPath = path.join(tempDir.path, 'talktoapp_$fileName');
        print('New image path: $newPath');
        
        // Copy the image to the new path
        final imageFile = File(picture.path);
        final newFile = await imageFile.copy(newPath);
        print('Image copied to: ${newFile.path}');
        
        // Compress the image to reduce file size
        // Note: For actual compression, you might want to use the 'flutter_image_compress' package
        // For now, we'll just return the copied file
        
        print('Image capture completed successfully');
        return newFile;
      } catch (e) {
        final error = 'Error capturing image: $e';
        print(error);
        _lastError = error;
        return null;
      }
    } else {
      print('Camera is already taking a picture');
      return null;
    }
  }

  Future<void> dispose() async {
    if (_controller != null) {
      print('Disposing camera controller...');
      await _controller!.dispose();
      _controller = null;
      _isInitialized = false;
      _isCameraReady = false;
      print('Camera disposed');
    }
  }
  
  bool get isInitialized => _isInitialized;
  bool get isCameraReady => _isCameraReady;
  CameraController? get controller => _controller;
  String get lastError => _lastError;
  List<CameraDescription> get cameras => _cameras;
}
