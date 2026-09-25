import 'dart:html' as html;
import 'web_notification_service.dart';

WebNotificationService getWebNotificationService() => _WebNotificationServiceWeb();

class _WebNotificationServiceWeb implements WebNotificationService {
  @override
  bool isSupported() {
    try {
      return html.Notification.supported;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!isSupported()) return false;
    try {
      final permission = await html.Notification.requestPermission();
      return permission == 'granted';
    } catch (_) {
      return false;
    }
  }

  @override
  bool isPermissionGranted() {
    if (!isSupported()) return false;
    try {
      return html.Notification.permission == 'granted';
    } catch (_) {
      return false;
    }
  }

  @override
  void showNotification({required String title, required String body, String? icon}) {
    if (!isPermissionGranted()) return;
    try {
      html.Notification(
        title,
        body: body,
        icon: icon ?? 'favicon.png',
      );
    } catch (_) {}
  }
}
