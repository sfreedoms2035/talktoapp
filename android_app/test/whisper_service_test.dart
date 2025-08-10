import 'package:flutter_test/flutter_test.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';
import '../lib/services/whisper_service.dart';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('WhisperService', () {
    test('triggerWord should return the correct trigger word', () {
      // Arrange
      final whisperService = WhisperService();
      
      // Act & Assert
      expect(whisperService.triggerWord, 'hey');
    });
    
    test('WhisperService constants should be correctly defined', () {
      // Arrange
      final whisperService = WhisperService();
      
      // Act & Assert
      expect(whisperService.triggerWord, 'hey');
      expect(WhisperService.TRIGGER_WORD, 'hey');
      expect(WhisperService.STOP_WORD, 'stop');
    });
  });
}
