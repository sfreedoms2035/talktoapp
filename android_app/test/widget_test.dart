import 'package:flutter_test/flutter_test.dart';
import 'package:talktoapp/main.dart';
import 'package:talktoapp/models/app_state.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App launches and displays home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => AppState(),
        child: const TalkToApp(),
      ),
    );

    // Verify that the app title is present
    expect(find.text('TalkToApp'), findsOneWidget);
    
    // Verify that status indicator is present
    expect(find.text('Ready'), findsOneWidget);
    
    // Verify that trigger detection widget is present
    expect(find.text('Trigger Detection'), findsOneWidget);
    
    // Verify that connection status widget is present
    expect(find.text('Connection Status'), findsOneWidget);
  });

  test('AppState updates correctly', () {
    final appState = AppState();
    
    // Test initial state
    expect(appState.status, AppStatus.idle);
    expect(appState.triggerDetected, '');
    expect(appState.connectionStatus, 'Disconnected');
    expect(appState.isConnected, false);
    
    // Test status update
    appState.updateStatus(AppStatus.listening);
    expect(appState.status, AppStatus.listening);
    
    // Test trigger detection
    appState.setTriggerDetected('Hey monitor');
    expect(appState.triggerDetected, 'Hey monitor');
    
    // Test connection status update
    appState.updateConnectionStatus('Connected', isConnected: true);
    expect(appState.connectionStatus, 'Connected');
    expect(appState.isConnected, true);
    
    // Test error handling
    appState.setError('Test error');
    expect(appState.status, AppStatus.error);
    expect(appState.errorMessage, 'Test error');
    
    // Test error clearing
    appState.clearError();
    expect(appState.errorMessage, '');
    expect(appState.status, AppStatus.idle);
  });
}
