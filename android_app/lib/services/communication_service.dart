import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CommunicationService {
  static const String _baseUrl = 'https://ley15vt1dv8emt-8000.proxy.runpod.net'; // RunPod service URL
  static const String _apiEndpoint = '$_baseUrl/process';
  
  bool _isConnected = false;
  String _serverUrl = _baseUrl;
  String _lastError = '';

  Future<void> connect() async {
    try {
      _lastError = '';
      _isConnected = false; // Reset connection status
      
      // Test connection with a simple ping
      final uri = Uri.parse('$_baseUrl/health');
      print('Attempting to connect to: $uri');
      
      // Try multiple times with increasing timeouts
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          print('Connection attempt $attempt of 3...');
          
          final response = await http.get(
            uri,
            headers: {'Content-Type': 'application/json'},
          ).timeout(Duration(seconds: 5 * attempt)); // Increase timeout with each attempt
          
          print('Response status: ${response.statusCode}');
          print('Response body: ${response.body}');
          
          if (response.statusCode == 200) {
            try {
              final jsonResponse = json.decode(response.body);
              print('Health check response: $jsonResponse');
              _isConnected = true;
              _lastError = '';
              print('Connection successful on attempt $attempt');
              return; // Success, exit the method
            } catch (jsonError) {
              print('Error parsing JSON response: $jsonError');
              // Continue with the response status check
              _isConnected = true;
              _lastError = '';
              print('Connection successful on attempt $attempt (non-JSON response)');
              return; // Success, exit the method
            }
          } else {
            _isConnected = false;
            _lastError = 'Server returned status code: ${response.statusCode}, body: ${response.body}';
            print('Failed attempt $attempt: $_lastError');
            // Continue to next attempt
          }
        } on SocketException catch (e) {
          _isConnected = false;
          _lastError = 'Network error on attempt $attempt: ${e.message}';
          print(_lastError);
          // Continue to next attempt
        } on TimeoutException catch (e) {
          _isConnected = false;
          _lastError = 'Connection timeout on attempt $attempt: ${e.message}';
          print(_lastError);
          // Continue to next attempt
        } catch (e) {
          _isConnected = false;
          _lastError = 'Connection failed on attempt $attempt: $e';
          print(_lastError);
          // Continue to next attempt
        }
        
        // Wait before next attempt
        if (attempt < 3) {
          print('Waiting before next connection attempt...');
          await Future.delayed(Duration(seconds: 1));
        }
      }
      
      // If we get here, all attempts failed
      print('All connection attempts failed. Last error: $_lastError');
    } catch (e) {
      _isConnected = false;
      _lastError = 'Unexpected error during connection: $e';
      print(_lastError);
    }
  }

  Future<String> sendRequest(String text, File imageFile) async {
    // Try to connect if not already connected
    if (!_isConnected) {
      print('Not connected. Attempting to connect before sending request...');
      await connect();
      
      if (!_isConnected) {
        throw Exception('Failed to connect to RunPod service: $_lastError');
      }
    }

    try {
      // Create multipart request
      final uri = Uri.parse(_apiEndpoint);
      print('Sending request to: $uri');
      print('Text content: $text');
      print('Image file path: ${imageFile.path}');
      
      // Verify image file exists and is readable
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist: ${imageFile.path}');
      }
      
      final request = http.MultipartRequest('POST', uri);
      
      // Add text field
      request.fields['text'] = text;
      print('Added text field');
      
      // Add image file
      final imageStream = http.ByteStream(imageFile.openRead());
      final imageLength = await imageFile.length();
      print('Image file size: $imageLength bytes');
      
      if (imageLength == 0) {
        throw Exception('Image file is empty: ${imageFile.path}');
      }
      
      final multipartFile = http.MultipartFile(
        'image',
        imageStream,
        imageLength,
        filename: 'captured_image.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      
      request.files.add(multipartFile);
      print('Added image file');
      
      // Send request with retry logic
      print('Sending HTTP request...');
      http.StreamedResponse? response;
      String? responseBody;
      
      // Try up to 2 times
      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          print('Send attempt $attempt of 2...');
          response = await request.send().timeout(const Duration(seconds: 30));
          print('Received response with status: ${response.statusCode}');
          
          // Process response
          responseBody = await response.stream.bytesToString();
          print('Response body: $responseBody');
          
          // If we got here, the request was sent successfully
          break;
        } catch (e) {
          print('Error on send attempt $attempt: $e');
          if (attempt == 2) {
            // This was the last attempt, rethrow
            rethrow;
          }
          // Wait before retry
          await Future.delayed(const Duration(seconds: 2));
        }
      }
      
      if (response == null || responseBody == null) {
        throw Exception('Failed to send request after multiple attempts');
      }
      
      if (response.statusCode == 200) {
        // Parse JSON response
        try {
          final jsonResponse = json.decode(responseBody);
          final responseText = jsonResponse['response'] ?? 'No response from AI';
          print('Successfully received response: $responseText');
          return responseText;
        } catch (jsonError) {
          print('Error parsing JSON response: $jsonError');
          // If JSON parsing fails, return the raw response
          return responseBody.isNotEmpty ? responseBody : 'No response from AI';
        }
      } else {
        final errorDetails = 'Server error: ${response.statusCode}, $responseBody';
        print(errorDetails);
        throw Exception(errorDetails);
      }
    } on SocketException catch (e) {
      _isConnected = false; // Mark as disconnected on network error
      throw Exception('Network connectivity issue: ${e.message}');
    } on TimeoutException catch (e) {
      throw Exception('Request timeout. The server may be slow to respond.');
    } catch (e) {
      throw Exception('Failed to send request: $e');
    }
  }

  void setServerUrl(String url) {
    _serverUrl = url;
    _isConnected = false; // Reset connection status
    _lastError = '';
  }

  bool get isConnected => _isConnected;
  String get serverUrl => _serverUrl;
  String get lastError => _lastError;
}
