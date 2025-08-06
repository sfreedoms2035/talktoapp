import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CommunicationService {
  static const String _baseUrl = 'http://69.30.85.95:8000'; // Replace with actual RunPod IP
  static const String _apiEndpoint = '$_baseUrl/process';
  
  bool _isConnected = false;
  String _serverUrl = _baseUrl;

  Future<void> connect() async {
    try {
      // Test connection with a simple ping
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        _isConnected = true;
      } else {
        _isConnected = false;
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      _isConnected = false;
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<String> sendRequest(String text, File imageFile) async {
    if (!_isConnected) {
      throw Exception('Not connected to server');
    }

    try {
      // Create multipart request
      final uri = Uri.parse(_apiEndpoint);
      final request = http.MultipartRequest('POST', uri);
      
      // Add text field
      request.fields['text'] = text;
      
      // Add image file
      final imageStream = http.ByteStream(imageFile.openRead());
      final imageLength = await imageFile.length();
      
      final multipartFile = http.MultipartFile(
        'image',
        imageStream,
        imageLength,
        filename: 'captured_image.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      
      request.files.add(multipartFile);
      
      // Send request
      final response = await request.send();
      
      // Process response
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        // Parse JSON response
        final jsonResponse = json.decode(responseBody);
        return jsonResponse['response'] ?? 'No response from AI';
      } else {
        throw Exception('Server error: ${response.statusCode}, $responseBody');
      }
    } catch (e) {
      throw Exception('Failed to send request: $e');
    }
  }

  void setServerUrl(String url) {
    _serverUrl = url;
    _isConnected = false; // Reset connection status
  }

  bool get isConnected => _isConnected;
  String get serverUrl => _serverUrl;
}
