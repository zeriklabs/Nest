import 'package:flutter/material.dart';

enum PageType {
  plain,
  ruled,
  grid,
  dotted,
}

class Notebook {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final DateTime createdAt;

  Notebook({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'color': color.value,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Notebook.fromJson(Map<String, dynamic> json) {
    DateTime parseDt(dynamic v) {
      if (v is String) return DateTime.parse(v);
      if (v is DateTime) return v;
      try {
        return (v as dynamic).toDate();
      } catch (_) {
        return DateTime.now();
      }
    }

    return Notebook(
      id: (json['id'] ?? json['docId'] ?? '').toString(),
      name: json['name'] as String? ?? 'Sin nombre',
      icon: IconData(json['icon'] as int? ?? Icons.book.codePoint, fontFamily: 'MaterialIcons'),
      color: Color(json['color'] as int? ?? 0xFF6366F1),
      createdAt: parseDt(json['createdAt']),
    );
  }
}
