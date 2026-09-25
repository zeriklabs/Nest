import 'web_message_listener_stub.dart'
    if (dart.library.html) 'web_message_listener_web.dart';

void setupWebEditorMessageListener(Function(String) onChanged) {
  listenToWebEditorMessage(onChanged);
}
