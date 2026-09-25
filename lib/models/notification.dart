import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final IconData icon;
  final Color? iconColor;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.icon = Icons.notifications_none_rounded,
    this.iconColor,
  });

  AppNotification copyWith({
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      icon: icon,
      iconColor: iconColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'icon': icon.codePoint,
      'iconColor': iconColor?.value,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    DateTime parseDt(dynamic v) {
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      if (v is DateTime) return v;
      if (v != null && v.runtimeType.toString() == 'Timestamp') {
        return (v as dynamic).toDate();
      }
      return DateTime.now();
    }

    bool parseBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
      return false;
    }

    return AppNotification(
      id: (json['id'] ?? json['docId'] ?? '').toString(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      timestamp: parseDt(json['timestamp']),
      isRead: parseBool(json['isRead']),
      icon: IconData(json['icon'] as int? ?? Icons.notifications_none_rounded.codePoint, fontFamily: 'MaterialIcons'),
      iconColor: json['iconColor'] != null ? Color(json['iconColor'] as int) : null,
    );
  }
}
