import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';

class StatusIndicator extends StatelessWidget {
  const StatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          Color statusColor;
          IconData statusIcon;
          String statusText;

          switch (appState.status) {
            case AppStatus.idle:
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
              statusText = 'Ready';
              break;
            case AppStatus.listening:
              statusColor = Colors.blue;
              statusIcon = Icons.hearing;
              statusText = 'Listening';
              break;
            case AppStatus.processing:
              statusColor = Colors.orange;
              statusIcon = Icons.settings;
              statusText = 'Processing';
              break;
            case AppStatus.sending:
              statusColor = Colors.purple;
              statusIcon = Icons.send;
              statusText = 'Sending';
              break;
            case AppStatus.receiving:
              statusColor = Colors.purple;
              statusIcon = Icons.download;
              statusText = 'Receiving';
              break;
            case AppStatus.speaking:
              statusColor = Colors.green;
              statusIcon = Icons.volume_up;
              statusText = 'Speaking';
              break;
            case AppStatus.error:
              statusColor = Colors.red;
              statusIcon = Icons.error;
              statusText = 'Error';
              break;
            case AppStatus.cameraInitializing:
              statusColor = Colors.orange;
              statusIcon = Icons.camera;
              statusText = 'Camera Initializing';
              break;
            case AppStatus.cameraReady:
              statusColor = Colors.green;
              statusIcon = Icons.camera_alt;
              statusText = 'Camera Ready';
              break;
            case AppStatus.triggerDetected:
              statusColor = Colors.purple;
              statusIcon = Icons.touch_app;
              statusText = 'Trigger Detected';
              break;
            case AppStatus.dataSending:
              statusColor = Colors.blue;
              statusIcon = Icons.upload;
              statusText = 'Sending Data';
              break;
            case AppStatus.dataSent:
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
              statusText = 'Data Sent';
              break;
            case AppStatus.dataFailed:
              statusColor = Colors.red;
              statusIcon = Icons.error;
              statusText = 'Data Failed';
              break;
            default:
              // Show initializing state when app is starting up
              if (appState.errorMessage.contains('Initializing')) {
                statusColor = Colors.blue;
                statusIcon = Icons.settings;
                statusText = 'Initializing';
              } else {
                statusColor = Colors.grey;
                statusIcon = Icons.help;
                statusText = 'Unknown';
              }
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 30,
              ),
              const SizedBox(width: 10),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
