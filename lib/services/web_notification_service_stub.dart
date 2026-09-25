import 'web_notification_service.dart';

WebNotificationService getWebNotificationService() => _WebNotificationServiceStub();

class _WebNotificationServiceStub implements WebNotificationService {
  @override
  Future<bool> requestPermission() async => false;

  @override
  bool isPermissionGranted() => false;

  @override
  bool isSupported() => false;

  @override
  void showNotification({required String title, required String body, String? icon}) {}
}
