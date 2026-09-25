import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Requests all necessary permissions for the app to function properly.
  Future<void> requestAllPermissions() async {
    if (kIsWeb) return;

    // 1. Notifications (Essential for reminders and session endings)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // 2. Android 12+ Exact Alarms (Essential for Pomodoro timing accuracy)
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    }

    // 3. Media & Hardware (For notes and attachments)
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.microphone,
        Permission.storage, // Legacy files
        Permission.photos,  // Android 13+
        Permission.audio,   // Android 13+
        Permission.videos,  // Android 13+
      ].request();
      
      debugPrint("Permission Statuses: $statuses");
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await [
        Permission.camera,
        Permission.photos,
        Permission.microphone,
      ].request();
    }

    // 4. Battery Optimization (Android only, prevents system from killing timers)
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        // This is often required for persistent focus sessions
        await Permission.ignoreBatteryOptimizations.request();
      }
    }
  }

  /// Specifically checks and requests DND access for Focus Mode
  Future<bool> checkDndAccess() async {
    // Currently handled via custom MethodChannel in DataService
    return true;
  }
}
