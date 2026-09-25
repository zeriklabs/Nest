import 'dart:html' as html;

void listenToWebEditorMessage(Function(String) onChanged) {
  html.window.onMessage.listen((event) {
    try {
      final data = event.data;
      if (data is Map && data['type'] == 'editor_change') {
        onChanged(data['content'].toString());
      }
    } catch (_) {}
  });
}
