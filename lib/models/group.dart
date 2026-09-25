import 'package:flutter/material.dart';
import 'group_post.dart';
import 'group_poll.dart';
import 'note.dart';
import 'reminder.dart';

class Group {
  final String id;
  String name;
  String? imagePath;
  final Color color;
  final String inviteCode;
  final List<String> members;
  final List<String> admins;
  final List<GroupPost> posts;
  final List<GroupPost>? _legacyPosts;
  List<GroupPost> get legacyPosts => _legacyPosts ?? const [];
  final List<Note> sharedNotes;
  final List<Reminder> sharedReminders;
  final List<GroupPoll> polls;

  Group({
    required this.id,
    required this.name,
    this.imagePath,
    this.color = const Color(0xFF6366F1),
    required this.inviteCode,
    this.members = const [],
    this.admins = const [],
    this.posts = const [],
    List<GroupPost>? legacyPosts,
    this.sharedNotes = const [],
    this.sharedReminders = const [],
    this.polls = const [],
  }) : _legacyPosts = legacyPosts ?? const [];

  Group copyWith({
    String? name,
    String? imagePath,
    Color? color,
    List<String>? members,
    List<String>? admins,
    List<GroupPost>? posts,
    List<GroupPost>? legacyPosts,
    List<Note>? sharedNotes,
    List<Reminder>? sharedReminders,
    List<GroupPoll>? polls,
  }) {
    return Group(
      id: id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      color: color ?? this.color,
      inviteCode: inviteCode,
      members: members ?? this.members,
      admins: admins ?? this.admins,
      posts: posts ?? this.posts,
      legacyPosts: legacyPosts ?? this.legacyPosts,
      sharedNotes: sharedNotes ?? this.sharedNotes,
      sharedReminders: sharedReminders ?? this.sharedReminders,
      polls: polls ?? this.polls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'color': '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
      'inviteCode': inviteCode,
      'members': members,
      'memberIds': members, // Duplicar para compatibilidad con queries de Firebase
      'admins': admins,
      'adminIds': admins,   // Versión legacy
      'adminId': admins.isNotEmpty ? admins.first : '', // Primer admin para la versión anterior
      'posts': posts.map((p) => p.toJson()).toList(),
      'mensajes': legacyPosts.map((p) => p.toJson()).toList(), // Compatibilidad Java
      'sharedNotes': sharedNotes.map((n) => n.toJson()).toList(),
      'sharedReminders': sharedReminders.map((r) => r.toJson()).toList(),
      'polls': polls.map((p) => p.toJson()).toList(),
    };
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    Color parseColor(dynamic v) {
      if (v == null) return const Color(0xFF6366F1);
      if (v is int) return Color(v).withAlpha(255);
      if (v is String) {
        final colorStr = v.replaceAll('#', '');
        try {
          if (colorStr.length == 6) {
            return Color(int.parse('FF$colorStr', radix: 16));
          } else {
            return Color(int.parse(colorStr, radix: 16));
          }
        } catch (_) {}
      }
      return const Color(0xFF6366F1);
    }

    final String groupId = (json['id'] ?? json['docId'] ?? '').toString();
    if (groupId.isEmpty) {
      debugPrint('Group.fromJson: ¡Atención! Grupo sin ID detectado: ${json['name']}');
    }

    List<String> parseList(dynamic v) {
      if (v is List) return List<String>.from(v.map((e) => e.toString()));
      if (v is Map) {
        // Manejar Maps que son en realidad arrays legacy (índices como claves)
        final List<String> list = [];
        try {
          final sortedKeys = v.keys.map((k) => int.tryParse(k.toString()) ?? -1).where((k) => k >= 0).toList()..sort();
          for (var key in sortedKeys) {
            list.add(v[key.toString()].toString());
          }
        } catch (_) {}
        return list;
      }
      return [];
    }

    return Group(
      id: groupId,
      name: (json['name'] ?? 'Sin nombre').toString(),
      imagePath: json['imagePath'] as String?,
      color: parseColor(json['color']),
      inviteCode: (json['inviteCode'] ?? '').toString(),
      members: parseList(json['members'] ?? json['memberIds']),
      admins: parseList(json['admins'] ?? json['adminIds']),
      posts: (json['posts'] is List)
          ? (json['posts'] as List)
              .where((p) => p is Map)
              .map((p) => GroupPost.fromJson(Map<String, dynamic>.from(p as Map)))
              .toList()
          : [],
      legacyPosts: (json['mensajes'] is List)
          ? (json['mensajes'] as List)
              .where((p) => p is Map)
              .map((p) => GroupPost.fromJson(Map<String, dynamic>.from(p as Map)))
              .toList()
          : [],
      sharedNotes: (json['sharedNotes'] is List)
          ? (json['sharedNotes'] as List)
              .where((n) => n is Map)
              .map((n) => Note.fromJson(Map<String, dynamic>.from(n as Map)))
              .toList()
          : [],
      sharedReminders: (json['sharedReminders'] is List)
          ? (json['sharedReminders'] as List)
              .where((r) => r is Map)
              .map((r) => Reminder.fromJson(Map<String, dynamic>.from(r as Map)))
              .toList()
          : [],
      polls: (json['polls'] is List)
          ? (json['polls'] as List)
              .where((p) => p is Map)
              .map((p) => GroupPoll.fromJson(Map<String, dynamic>.from(p as Map)))
              .toList()
          : [],
    );
  }
}
