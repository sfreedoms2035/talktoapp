import 'package:flutter/foundation.dart';

enum AppStatus { 
  idle, 
  listening, 
  processing, 
  sending, 
  receiving, 
  speaking, 
  error,
  triggerDetected, // New state for trigger word detection
  cameraInitializing, // New state for camera initialization
  cameraReady, // New state for camera ready
  dataSending, // New state for data communication
  dataSent, // New state for data sent successfully
  dataFailed, // New state for data communication failed
  microphoneActive, // State for active microphone
  microphoneInactive, // State for inactive microphone
  textOnlyMode, // State for text-only mode
  whisperActive // State for Whisper transcription active
}

enum TranscriptionMethod {
  speechToText, // Default method using speech_to_text package
  whisper // Whisper-based transcription
}

class AppState extends ChangeNotifier {
  AppStatus _status = AppStatus.idle;
  String _triggerDetected = '';
  String _connectionStatus = 'Disconnected';
  String _errorMessage = '';
  bool _isConnected = false;
  bool _isTriggerWordDetected = false;
  String _lastDataSent = '';
  String _dataCommunicationStatus = 'Not sent';
  DateTime? _lastDataSentTime;
  bool _isMicrophoneActive = false;
  bool _isTextOnlyMode = false;
  TranscriptionMethod _transcriptionMethod = TranscriptionMethod.speechToText;
  bool _isWhisperActive = false;

  AppStatus get status => _status;
  String get triggerDetected => _triggerDetected;
  String get connectionStatus => _connectionStatus;
  String get errorMessage => _errorMessage;
  bool get isConnected => _isConnected;
  bool get isTriggerWordDetected => _isTriggerWordDetected;
  String get lastDataSent => _lastDataSent;
  String get dataCommunicationStatus => _dataCommunicationStatus;
  DateTime? get lastDataSentTime => _lastDataSentTime;
  bool get isMicrophoneActive => _isMicrophoneActive;
  bool get isTextOnlyMode => _isTextOnlyMode;
  TranscriptionMethod get transcriptionMethod => _transcriptionMethod;
  bool get isWhisperActive => _isWhisperActive;

  void updateStatus(AppStatus status) {
    _status = status;
    notifyListeners();
  }

  void setTriggerDetected(String trigger) {
    _triggerDetected = trigger;
    _isTriggerWordDetected = trigger.isNotEmpty;
    notifyListeners();
  }

  void updateConnectionStatus(String status, {bool isConnected = false}) {
    _connectionStatus = status;
    _isConnected = isConnected;
    notifyListeners();
  }

  void setError(String error) {
    _errorMessage = error;
    // Don't set to error state for informational messages
    // Only set to error state for actual errors
    if (error.contains('failed') || error.contains('error') || error.contains('Error')) {
      _status = AppStatus.error;
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    if (_status == AppStatus.error) {
      _status = AppStatus.idle;
    }
    notifyListeners();
  }

  void setDataCommunicationStatus(String status, {String? dataInfo}) {
    _dataCommunicationStatus = status;
    if (dataInfo != null) {
      _lastDataSent = dataInfo;
    }
    if (status == 'Sent successfully') {
      _lastDataSentTime = DateTime.now();
    }
    notifyListeners();
  }

  void setTriggerWordDetected(bool detected) {
    _isTriggerWordDetected = detected;
    notifyListeners();
  }

  void setCameraStatus(bool isReady) {
    if (isReady) {
      _status = AppStatus.cameraReady;
    } else {
      _status = AppStatus.cameraInitializing;
    }
    notifyListeners();
  }
  
  void setMicrophoneActive(bool active) {
    _isMicrophoneActive = active;
    if (active) {
      _status = AppStatus.microphoneActive;
    } else {
      _status = AppStatus.microphoneInactive;
    }
    notifyListeners();
  }
  
  void setTextOnlyMode(bool enabled) {
    _isTextOnlyMode = enabled;
    if (enabled) {
      _status = AppStatus.textOnlyMode;
    } else {
      _status = AppStatus.idle;
    }
    notifyListeners();
  }
  
  void setTranscriptionMethod(TranscriptionMethod method) {
    _transcriptionMethod = method;
    if (method == TranscriptionMethod.whisper) {
      _isWhisperActive = true;
      _status = AppStatus.whisperActive;
    } else {
      _isWhisperActive = false;
      if (_status == AppStatus.whisperActive) {
        _status = AppStatus.idle;
      }
    }
    notifyListeners();
  }
  
  void toggleTranscriptionMethod() {
    if (_transcriptionMethod == TranscriptionMethod.speechToText) {
      setTranscriptionMethod(TranscriptionMethod.whisper);
    } else {
      setTranscriptionMethod(TranscriptionMethod.speechToText);
    }
  }
}
