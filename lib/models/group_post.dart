import 'group_comment.dart';

class GroupPost {
  final String id;
  final String author;
  final String? authorId;
  final String? authorPhotoUrl;
  final String title;
  final String content;
  final List<String> images;
  final DateTime timestamp;
  final Map<String, List<String>> reactions;
  final List<GroupComment> comments;
  final String type; // ANNOUNCEMENT, NOTE, TASK, POLL
  final bool urgent;
  final int expiryTimestamp;

  // Task-specific fields (for compatibility)
  final List<Map<String, dynamic>>? taskAlerts;
  final String? taskCategory;
  final String? taskDate;
  final List<int>? taskDaysOfWeek;
  final String? taskEndTime;
  final String? taskLocation;
  final String? taskRepeat;
  final int taskRepeatCount;
  final String? taskRepeatEndDate;
  final String? taskStartTime;
  final String? taskTime;
  final bool taskAllDay;

  // Poll-specific fields (for compatibility with Java Map structure)
  final List<String>? pollOptions;
  final Map<String, List<String>>? pollVotes;

  GroupPost({
    required this.id,
    required this.author,
    this.authorId,
    this.authorPhotoUrl,
    required this.title,
    required this.content,
    this.images = const [],
    required this.timestamp,
    this.reactions = const {},
    this.comments = const [],
    this.type = 'ANNOUNCEMENT',
    this.urgent = false,
    this.expiryTimestamp = 0,
    this.taskAlerts,
    this.taskCategory,
    this.taskDate,
    this.taskDaysOfWeek,
    this.taskEndTime,
    this.taskLocation,
    this.taskRepeat,
    this.taskRepeatCount = 0,
    this.taskRepeatEndDate,
    this.taskStartTime,
    this.taskTime,
    this.taskAllDay = false,
    this.pollOptions,
    this.pollVotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': author,
      'author': author,
      'authorId': authorId ?? '',
      'authorPhotoUrl': authorPhotoUrl ?? '',
      'title': title,
      'content': content,
      'images': images,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'reactions': reactions,
      'comments': comments.map((c) => c.toJson()).toList(),
      'type': type,
      'urgent': urgent,
      'expiryTimestamp': expiryTimestamp,
      'taskAlerts': taskAlerts ?? [{
        'taskAllDay': taskAllDay,
        'taskCategory': taskCategory,
      }],
      'taskCategory': taskCategory,
      'taskDate': taskDate,
      'taskDaysOfWeek': taskDaysOfWeek ?? [],
      'taskEndTime': taskEndTime,
      'taskLocation': taskLocation,
      'taskRepeat': taskRepeat,
      'taskRepeatCount': taskRepeatCount,
      'taskRepeatEndDate': taskRepeatEndDate,
      'taskStartTime': taskStartTime,
      'taskTime': taskTime,
      'taskAllDay': taskAllDay,
      'pollOptions': pollOptions ?? [],
      'pollVotes': pollVotes ?? {},
    };
  }

  factory GroupPost.fromJson(Map<String, dynamic> json) {
    DateTime parseTime(dynamic ts) {
      if (ts == null || ts == 0) return DateTime(2020, 1, 1); // Fallback to past for legacy data
      if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
      if (ts is String) return DateTime.tryParse(ts) ?? DateTime(2020, 1, 1);
      try {
        return (ts as dynamic).toDate();
      } catch (_) {
        return DateTime(2020, 1, 1);
      }
    }

    List<String> parseList(dynamic v) {
      if (v is List) return List<String>.from(v.map((e) => e.toString()));
      if (v is Map) {
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

    Map<String, List<String>> parsePollVotes(dynamic v) {
      if (v is Map) {
        return v.map((key, value) {
          if (value is Iterable) {
            return MapEntry(key.toString(), List<String>.from(value.map((e) => e.toString())));
          } else if (value is Map) {
            return MapEntry(key.toString(), parseList(value));
          }
          return MapEntry(key.toString(), <String>[]);
        });
      }
      return {};
    }

    return GroupPost(
      id: (json['id'] ?? '').toString(),
      author: (json['authorName'] ?? json['author'] ?? json['autor'] ?? 'Anónimo').toString(),
      authorId: json['authorId']?.toString(),
      authorPhotoUrl: json['authorPhotoUrl']?.toString(),
      title: (json['title'] ?? json['titulo'] ?? '').toString(),
      content: (json['content'] ?? json['contenido'] ?? json['mensaje'] ?? '').toString(),
      images: parseList(json['images'] ?? json['imagenes']),
      timestamp: parseTime(json['timestamp'] ?? json['fecha']),
      reactions: (json['reactions'] is Map) 
          ? (json['reactions'] as Map).map((key, value) => MapEntry(key.toString(), value is Iterable ? List<String>.from(value) : (value is Map ? parseList(value) : [])))
          : {},
      comments: (json['comments'] is List)
          ? (json['comments'] as List)
              .where((c) => c is Map)
              .map((c) => GroupComment.fromJson(Map<String, dynamic>.from(c as Map)))
              .toList()
          : [],
      type: (json['type'] ?? 'ANNOUNCEMENT').toString().toUpperCase(),
      urgent: json['urgent'] == true,
      expiryTimestamp: json['expiryTimestamp'] as int? ?? 0,
      taskAlerts: json['taskAlerts'] is List 
          ? (json['taskAlerts'] as List).map((i) => Map<String, dynamic>.from(i as Map)).toList()
          : (json['taskAlerts'] is Map ? [Map<String, dynamic>.from(json['taskAlerts'] as Map)] : null),
      taskCategory: json['taskCategory']?.toString(),
      taskDate: json['taskDate']?.toString(),
      taskDaysOfWeek: json['taskDaysOfWeek'] is List ? List<int>.from(json['taskDaysOfWeek']) : null,
      taskEndTime: json['taskEndTime']?.toString(),
      taskLocation: json['taskLocation']?.toString(),
      taskRepeat: json['taskRepeat']?.toString(),
      taskRepeatCount: json['taskRepeatCount'] as int? ?? 0,
      taskRepeatEndDate: json['taskRepeatEndDate']?.toString(),
      taskStartTime: json['taskStartTime']?.toString(),
      taskTime: json['taskTime']?.toString(),
      taskAllDay: json['taskAllDay'] == true,
      pollOptions: json['pollOptions'] is List ? List<String>.from(json['pollOptions']) : (json['pollOptions'] is Map ? parseList(json['pollOptions']) : null),
      pollVotes: parsePollVotes(json['pollVotes']),
    );
  }
}
