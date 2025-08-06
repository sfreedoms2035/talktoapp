import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;

  Future<void> initializeCamera() async {
    try {
      _cameras = await availableCameras();
      
      // Find the rear camera (usually the first one or the one with direction back)
      CameraDescription? rearCamera;
      for (var camera in _cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          rearCamera = camera;
          break;
        }
      }
      
      // If no rear camera found, use the first camera
      rearCamera ??= _cameras.isNotEmpty ? _cameras.first : null;
      
      if (rearCamera == null) {
        throw Exception('No camera found');
      }
      
      _controller = CameraController(
        rearCamera,
        ResolutionPreset.medium, // Use medium resolution for balance between quality and performance
        enableAudio: false, // We don't need audio for image capture
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await _controller!.initialize();
      _isInitialized = true;
    } catch (e) {
      print('Error initializing camera: $e');
      _isInitialized = false;
    }
  }

  Future<File?> captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }
    
    if (!_controller!.value.isTakingPicture) {
      try {
        // Take the picture
        final XFile picture = await _controller!.takePicture();
        
        // Get the temporary directory
        final tempDir = await getTemporaryDirectory();
        
        // Create a new file path
        final fileName = path.basename(picture.path);
        final newPath = path.join(tempDir.path, 'talktoapp_$fileName');
        
        // Copy the image to the new path
        final imageFile = File(picture.path);
        final newFile = await imageFile.copy(newPath);
        
        // Compress the image to reduce file size
        // Note: For actual compression, you might want to use the 'flutter_image_compress' package
        // For now, we'll just return the copied file
        
        return newFile;
      } catch (e) {
        print('Error capturing image: $e');
        return null;
      }
    }
    
    return null;
  }

  Future<void> dispose() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
      _isInitialized = false;
    }
  }
  
  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;
}
