import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/web_message_listener.dart';

class RichTextEditorWebView extends StatefulWidget {
  final String initialHtml;
  final Function(String) onChanged;
  final Function(Map<String, bool>)? onStyleChanged;
  final bool readOnly;
  final Color? backgroundColor;
  final Color textColor;

  const RichTextEditorWebView({
    super.key,
    required this.initialHtml,
    required this.onChanged,
    this.onStyleChanged,
    this.readOnly = false,
    this.backgroundColor,
    this.textColor = Colors.black,
  });

  @override
  State<RichTextEditorWebView> createState() => RichTextEditorWebViewState();
}

class RichTextEditorWebViewState extends State<RichTextEditorWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController();
    
    // Configuración segura por plataforma
    try {
      if (!kIsWeb) {
        _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
        _controller.setBackgroundColor(widget.backgroundColor ?? Colors.transparent);
      } else {
        // En la Web, usamos un canal de respaldo robusto
        _setupWebMessageListener();
      }
      
      // Intentar añadir canales de comunicación (esencial para detectar escritura)
      _controller.addJavaScriptChannel(
        'FlutterEditor',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint("WebView: Recibido contenido (${message.message.length} bytes)");
          widget.onChanged(message.message);
        },
      );
      
      _controller.addJavaScriptChannel(
        'FlutterStyle',
        onMessageReceived: (JavaScriptMessage message) {
          if (widget.onStyleChanged != null) {
            try {
              final Map<String, dynamic> data = jsonDecode(message.message);
              widget.onStyleChanged!(data.map((key, value) => MapEntry(key, value as bool)));
            } catch (_) {}
          }
        },
      );
    } catch (e) {
      debugPrint("WebView (Web) info: Algunas funciones de canal se inicializarán bajo demanda: $e");
    }

    _controller.loadHtmlString(_buildEditorHtml(
      initialReadOnly: widget.readOnly,
    ));
  }

  // Listener de respaldo para Web
  void _setupWebMessageListener() {
    if (!kIsWeb) return;
    setupWebEditorMessageListener((message) {
      widget.onChanged(message);
    });
  }

  @override
  void didUpdateWidget(RichTextEditorWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.readOnly != widget.readOnly) {
      if (!kIsWeb) {
        _controller.runJavaScript('window.setReadOnly(${widget.readOnly});');
      } else {
        // En la Web, si el JS dinámico falla, recargamos el HTML con el estado correcto
        _controller.loadHtmlString(_buildEditorHtml(
          initialReadOnly: widget.readOnly,
        ));
      }
    }

    if (oldWidget.backgroundColor != widget.backgroundColor || oldWidget.textColor != widget.textColor) {
      _updateColors();
    }
  }

  void _updateColors() {
    final bgColor = widget.backgroundColor ?? Colors.transparent;
    if (!kIsWeb) {
      _controller.setBackgroundColor(bgColor);
    }

    final hexColor = bgColor == Colors.transparent 
        ? 'transparent' 
        : '#${bgColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    
    final hexTextColor = '#${widget.textColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    
    if (!kIsWeb) {
      _controller.runJavaScript('''
          document.body.style.backgroundColor = "$hexColor";
          document.body.style.color = "$hexTextColor";
          document.getElementById('editor').style.color = "$hexTextColor";
      ''');
    }
  }

  String _buildEditorHtml({required bool initialReadOnly}) {
    final bgColor = widget.backgroundColor ?? Colors.transparent;
    final hexColor = bgColor == Colors.transparent 
        ? 'transparent' 
        : '#${bgColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    
    final hexTextColor = '#${widget.textColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    final String content = widget.initialHtml.isEmpty ? '<br>' : widget.initialHtml;

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <style>
        * { -webkit-tap-highlight-color: transparent; box-sizing: border-box; }
        body {
            margin: 0;
            padding: 24px 20px 100px 20px;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background-color: $hexColor;
            color: $hexTextColor;
            font-size: 18px;
            line-height: 1.5;
            min-height: 100vh;
            overflow-x: hidden;
        }
        #editor {
            outline: none;
            min-height: 80vh;
            white-space: pre-wrap;
            word-wrap: break-word;
            color: inherit !important;
        }
        #editor:empty:before {
            content: "Escribe algo aquí...";
            color: rgba(128, 128, 128, 0.5);
        }
        blockquote { border-left: 4px solid currentColor; margin: 10px 0; padding-left: 16px; opacity: 0.8; }
        pre, code { font-family: monospace; background: rgba(0,0,0,0.05); padding: 2px 4px; border-radius: 4px; }
        h1, h2, h3 { margin: 16px 0 8px 0; font-weight: bold; }
    </style>
    <script>
        window.sendContent = function() {
            const editor = document.getElementById('editor');
            const html = editor.innerHTML;
            if (window.FlutterEditor) {
                window.FlutterEditor.postMessage(html);
            }
            // Fallback para versiones web problemáticas
            window.parent.postMessage({type: 'editor_change', content: html}, '*');
        };
        window.sendStyle = function() {
            if (window.FlutterStyle) {
                const styles = {
                    'bold': document.queryCommandState('bold'),
                    'italic': document.queryCommandState('italic'),
                    'underline': document.queryCommandState('underline'),
                    'insertUnorderedList': document.queryCommandState('insertUnorderedList'),
                    'insertOrderedList': document.queryCommandState('insertOrderedList'),
                };
                window.FlutterStyle.postMessage(JSON.stringify(styles));
            }
        };
        window.execCommand = function(cmd, val = null) {
            document.execCommand(cmd, false, val);
            window.sendContent();
            window.sendStyle();
        };
        window.onPageLoad = function() {
            const editor = document.getElementById('editor');
            if (${!initialReadOnly}) {
                editor.focus();
                // Cursor to end
                const range = document.createRange();
                const sel = window.getSelection();
                range.selectNodeContents(editor);
                range.collapse(false);
                sel.removeAllRanges();
                sel.addRange(range);
            }
        };
    </script>
</head>
<body onload="onPageLoad()">
    <div id="editor" contenteditable="${widget.readOnly ? 'false' : 'true'}" oninput="sendContent()">$content</div>
    <script>
        document.addEventListener('selectionchange', window.sendStyle);
    </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }

  void format(String command, [String? value]) {
    if (kIsWeb) return; // Comandos de formato no soportados vía runJavaScript en esta versión web
    final jsValue = value != null ? "'$value'" : "null";
    _controller.runJavaScript('window.execCommand("$command", $jsValue);');
  }
}
