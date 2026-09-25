import 'web_notification_service_stub.dart'
    if (dart.library.html) 'web_notification_service_web.dart';

abstract class WebNotificationService {
  factory WebNotificationService() => getWebNotificationService();

  Future<bool> requestPermission();
  bool isPermissionGranted();
  bool isSupported();
  void showNotification({required String title, required String body, String? icon});
}
