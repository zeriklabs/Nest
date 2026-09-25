import 'dart:convert';
import 'package:flutter/material.dart';
import 'notebook.dart';
import 'group_comment.dart';
import '../utils/html_utils.dart';

class Note {
  final String id;
  final String author;
  final String? authorId;
  final String? authorPhotoUrl;
  final String title;
  final String content; // JSON string of Fleather/Parchment Delta
  final String? htmlContent; // HTML representation for cross-platform compatibility
  final Color? backgroundColor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notebookId; // Referencia al ID de la libreta
  final String? focusSessionId; // Referencia a la sesión de enfoque
  final PageType pageType;
  final List<String>? sharedWith;
  final Map<String, List<String>> reactions;
  final List<GroupComment> comments;

  Note({
    required this.id,
    this.author = 'Anónimo',
    this.authorId,
    this.authorPhotoUrl,
    required this.title,
    required this.content,
    this.htmlContent,
    this.backgroundColor,
    required this.createdAt,
    required this.updatedAt,
    this.notebookId,
    this.focusSessionId,
    this.pageType = PageType.plain,
    this.sharedWith = const [],
    this.reactions = const {},
    this.comments = const [],
  });

  bool get isQuickNote => notebookId == null;

  List<String> get sharedWithList => sharedWith ?? [];

  String get previewText {
    try {
      final dynamic decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded
            .map((op) => (op is Map && op['insert'] is String) ? op['insert'] : '')
            .join('')
            .trim();
      }
    } catch (_) {}
    return '';
  }

  Note copyWith({
    String? author,
    String? authorId,
    String? authorPhotoUrl,
    String? title,
    String? content,
    String? htmlContent,
    Color? backgroundColor,
    DateTime? updatedAt,
    String? notebookId,
    String? focusSessionId,
    PageType? pageType,
    List<String>? sharedWith,
    Map<String, List<String>>? reactions,
    List<GroupComment>? comments,
  }) {
    return Note(
      id: id,
      author: author ?? this.author,
      authorId: authorId ?? this.authorId,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      title: title ?? this.title,
      content: content ?? this.content,
      htmlContent: htmlContent ?? this.htmlContent,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notebookId: notebookId ?? this.notebookId,
      focusSessionId: focusSessionId ?? this.focusSessionId,
      pageType: pageType ?? this.pageType,
      sharedWith: sharedWith ?? this.sharedWith,
      reactions: reactions ?? this.reactions,
      comments: comments ?? this.comments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author,
      'authorName': author,
      'authorId': authorId ?? '',
      'authorPhotoUrl': authorPhotoUrl ?? '',
      'title': title,
      'text': htmlContent ?? previewText, // Use HTML if available for Java compatibility
      'content': content,  // Keep Delta for Flutter
      'html': htmlContent, // Explicit field for HTML
      'color': backgroundColor?.value.toString() ?? '-1', // Java expects String
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'timestamp': createdAt.millisecondsSinceEpoch, // For unified posts
      'type': 'NOTE',
      'notebookId': notebookId,
      'focusSessionId': focusSessionId,
      'pageType': pageType.index,
      'sharedWith': sharedWithList,
    };
  }

    factory Note.fromJson(Map<String, dynamic> json) {
    DateTime parseDt(dynamic v) {
      if (v is String) return DateTime.tryParse(v) ?? DateTime(2020, 1, 1);
      if (v is DateTime) return v;
      if (v != null && v.runtimeType.toString() == 'Timestamp') {
        return (v as dynamic).toDate();
      }
      return DateTime(2020, 1, 1);
    }

    Color? parseColor(dynamic v) {
      if (v == null) return null;
      if (v is int) return Color(v).withAlpha(255);
      if (v is String) {
        String s = v.toLowerCase().trim();
        if (s.isEmpty) return null;

        // Formatos con prefijo
        if (s.startsWith('0x')) return Color(int.parse(s)).withAlpha(255);
        if (s.startsWith('#')) {
          if (s.length == 7) s = s.replaceFirst('#', '0xFF');
          else if (s.length == 9) s = s.replaceFirst('#', '0x');
          return Color(int.parse(s));
        }

        // Mapeo de nombres de colores básicos si venían como string
        const colorNames = {
          'red': 0xFFFFCDD2, 'pink': 0xFFF8BBD0, 'purple': 0xFFE1BEE7,
          'deep_purple': 0xFFD1C4E9, 'indigo': 0xFFC5CAE9, 'blue': 0xFFBBDEFB,
          'light_blue': 0xFFB3E5FC, 'cyan': 0xFFB2EBF2, 'teal': 0xFFB2DFDB,
          'green': 0xFFC8E6C9, 'light_green': 0xFFDCEDC8, 'lime': 0xFFF0F4C3,
          'yellow': 0xFFFFF9C4, 'amber': 0xFFFFECB3, 'orange': 0xFFFFE0B2,
          'deep_orange': 0xFFFFCCBC, 'brown': 0xFFD7CCC8, 'grey': 0xFFF5F5F5,
          'blue_grey': 0xFFCFD8DC, 'white': 0xFFFFFFFF,
        };
        if (colorNames.containsKey(s)) return Color(colorNames[s]!);

        // Hexadecimal puro sin prefijo (ej: "ff0000")
        if (RegExp(r'^[0-9a-f]{6}$').hasMatch(s)) return Color(int.parse('0xFF$s'));
        if (RegExp(r'^[0-9a-f]{8}$').hasMatch(s)) return Color(int.parse('0x$s'));

        // Intento de conversión decimal (ej: "-12345" o "4294967295")
        try {
          final intVal = int.parse(s);
          return Color(intVal).withAlpha(255);
        } catch (_) {}
      }
      return null;
    }

    String rawContent = (json['content'] ?? json['text'] ?? '').toString();

    // Si el contenido es de la app vieja (HTML o codificación incorrecta), lo limpiamos
    if (rawContent.startsWith('<') || !rawContent.contains('[{"insert"')) {
      rawContent = HtmlUtils.htmlToDelta(rawContent);
    }

    // Buscar el color en campos comunes de la versión anterior
    final dynamic colorValue = json['backgroundColor'] ??
                             json['color'] ??
                             json['bgColor'] ??
                             json['noteColor'] ??
                             json['note_color'] ??
                             json['selectedColor'] ??
                             json['colorIndex'] ??
                             json['categoryColor'];

    // Si es un colorIndex (común en algunas versiones Android legacy)
    Color? finalColor;
    if (colorValue is int && colorValue < 20 && colorValue >= 0) {
      const legacyPalette = [
        0xFFF5F5F5, 0xFFFFCDD2, 0xFFF8BBD0, 0xFFE1BEE7, 0xFFD1C4E9,
        0xFFC5CAE9, 0xFFBBDEFB, 0xFFB3E5FC, 0xFFB2EBF2, 0xFFB2DFDB,
        0xFFC8E6C9, 0xFFDCEDC8, 0xFFF0F4C3, 0xFFFFF9C4, 0xFFFFECB3,
        0xFFFFE0B2, 0xFFFFCCBC, 0xFFD7CCC8, 0xFFCFD8DC, 0xFFFFFFFF
      ];
      finalColor = Color(legacyPalette[colorValue]);
    } else {
      finalColor = parseColor(colorValue);
    }

    return Note(
      id: (json['id'] ?? json['docId'] ?? '').toString(),
      author: (json['authorName'] ?? json['author'] ?? 'Anónimo').toString(),
      authorId: json['authorId']?.toString(),
      authorPhotoUrl: json['authorPhotoUrl']?.toString(),
      title: json['title'] as String? ?? '',
      content: rawContent,
      htmlContent: json['html'] ?? json['text'],
      backgroundColor: finalColor,
      createdAt: parseDt(json['createdAt'] ?? json['timestamp']),
      updatedAt: parseDt(json['updatedAt'] ?? json['timestamp']),
      notebookId: json['notebookId'] as String?,
      focusSessionId: json['focusSessionId'] as String?,
      pageType: PageType.values[(json['pageType'] is int && (json['pageType'] as int) < PageType.values.length) ? (json['pageType'] as int) : 0],
      sharedWith: json['sharedWith'] != null ? List<String>.from(json['sharedWith']) : [],
    );
  }
}
