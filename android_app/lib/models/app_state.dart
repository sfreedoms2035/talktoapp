import 'package:flutter/foundation.dart';

enum AppStatus { idle, listening, processing, sending, receiving, speaking, error }

class AppState extends ChangeNotifier {
  AppStatus _status = AppStatus.idle;
  String _triggerDetected = '';
  String _connectionStatus = 'Disconnected';
  String _errorMessage = '';
  bool _isConnected = false;

  AppStatus get status => _status;
  String get triggerDetected => _triggerDetected;
  String get connectionStatus => _connectionStatus;
  String get errorMessage => _errorMessage;
  bool get isConnected => _isConnected;

  void updateStatus(AppStatus status) {
    _status = status;
    notifyListeners();
  }

  void setTriggerDetected(String trigger) {
    _triggerDetected = trigger;
    notifyListeners();
  }

  void updateConnectionStatus(String status, {bool isConnected = false}) {
    _connectionStatus = status;
    _isConnected = isConnected;
    notifyListeners();
  }

  void setError(String error) {
    _errorMessage = error;
    _status = AppStatus.error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    if (_status == AppStatus.error) {
      _status = AppStatus.idle;
    }
    notifyListeners();
  }
}
