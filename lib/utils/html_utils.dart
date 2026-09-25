import 'dart:convert';

class HtmlUtils {
  /// Basic Delta to HTML converter
  static String deltaToHtml(String deltaJson) {
    try {
      final List<dynamic> delta = jsonDecode(deltaJson);
      StringBuffer html = StringBuffer();
      
      for (var op in delta) {
        if (op is Map && op.containsKey('insert')) {
          dynamic insert = op['insert'];
          if (insert is! String) continue;

          Map<String, dynamic>? attrs = op['attributes'] as Map<String, dynamic>?;
          String text = insert;

          // Handle basic inline styles
          if (attrs != null) {
            if (attrs['bold'] == true) text = '<b>$text</b>';
            if (attrs['italic'] == true) text = '<i>$text</i>';
            if (attrs['underline'] == true) text = '<u>$text</u>';
            if (attrs['strikethrough'] == true) text = '<s>$text</s>';
          }

          // In Delta, a trailing \n with attributes means the preceding line has block styles.
          // For this basic converter, we'll just treat \n as <br>
          html.write(text.replaceAll('\n', '<br>'));
        }
      }
      return html.toString();
    } catch (e) {
      return '';
    }
  }

  /// Basic HTML to Delta converter (for imports)
  static String htmlToDelta(String html) {
    if (!html.contains('<') && !html.contains('>')) {
      return jsonEncode([{"insert": "$html\n"}]);
    }

    String cleanText = html
        .replaceAll(RegExp(r'</p>|<br>|</div>|</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>', caseSensitive: false), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&aacute;', 'á').replaceAll('&Aacute;', 'Á')
        .replaceAll('&eacute;', 'é').replaceAll('&Eacute;', 'É')
        .replaceAll('&iacute;', 'í').replaceAll('&Iacute;', 'Í')
        .replaceAll('&oacute;', 'ó').replaceAll('&Oacute;', 'Ó')
        .replaceAll('&uacute;', 'ú').replaceAll('&Uacute;', 'Ú')
        .replaceAll('&ntilde;', 'ñ').replaceAll('&Ntilde;', 'Ñ')
        .replaceAll('&iexcl;', '¡').replaceAll('&iquest;', '¿')
        .replaceAll('&ldquo;', '“').replaceAll('&rdquo;', '”')
        .replaceAll('&lsquo;', '‘').replaceAll('&rsquo;', '’')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&');

    // Decode numerical entities
    cleanText = cleanText.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      return String.fromCharCode(int.parse(match.group(1)!));
    });
    
    return jsonEncode([{"insert": "${cleanText.trim()}\n"}]);
  }
}
