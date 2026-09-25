import 'group_comment.dart';

class Reminder {
  final String id;
  final String author;
  final String? authorId;
  final String? authorPhotoUrl;
  final String title;
  final String date;
  final String? time;
  final String category;
  final String? location;
  final String? description;
  final String? subjectId;
  final List<String> sharedWith;
  final List<String> attachments; // Paths to files or images
  final bool isUrgent;
  final bool isAllDay;
  final DateTime? endDate;
  bool isCompleted;
  final DateTime? completedAt;
  final DateTime dateTime;
  final String? programId;
  final String? calendarEventId;
  final Map<String, List<String>> reactions;
  final List<GroupComment> comments;

  Reminder({
    required this.id,
    this.author = 'Anónimo',
    this.authorId,
    this.authorPhotoUrl,
    required this.title,
    required this.date,
    this.time,
    required this.category,
    this.location,
    this.description,
    this.subjectId,
    this.sharedWith = const [],
    this.attachments = const [],
    this.isUrgent = false,
    this.isAllDay = false,
    this.endDate,
    this.isCompleted = false,
    this.completedAt,
    required this.dateTime,
    this.programId,
    this.calendarEventId,
    this.reactions = const {},
    this.comments = const [],
  });

  bool isHappeningOn(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final startDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    if (endDate == null) {
      return day.isAtSameMomentAs(startDay);
    }
    final endDay = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return (day.isAtSameMomentAs(startDay) || day.isAfter(startDay)) &&
           (day.isAtSameMomentAs(endDay) || day.isBefore(endDay));
  }

  Reminder copyWith({
    String? title,
    String? authorId,
    String? authorPhotoUrl,
    String? date,
    String? time,
    String? category,
    String? location,
    String? description,
    String? subjectId,
    List<String>? sharedWith,
    List<String>? attachments,
    bool? isUrgent,
    bool? isAllDay,
    DateTime? endDate,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? dateTime,
    String? programId,
    String? calendarEventId,
    Map<String, List<String>>? reactions,
    List<GroupComment>? comments,
  }) {
    return Reminder(
      id: id,
      author: author,
      authorId: authorId ?? this.authorId,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      category: category ?? this.category,
      location: location ?? this.location,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      sharedWith: sharedWith ?? this.sharedWith,
      attachments: attachments ?? this.attachments,
      isUrgent: isUrgent ?? this.isUrgent,
      isAllDay: isAllDay ?? this.isAllDay,
      endDate: endDate ?? this.endDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      dateTime: dateTime ?? this.dateTime,
      programId: programId ?? this.programId,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      reactions: reactions ?? this.reactions,
      comments: comments ?? this.comments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': author,
      'author': author,
      'authorId': authorId ?? '',
      'authorPhotoUrl': authorPhotoUrl ?? '',
      'title': title,
      'date': date,
      'time': time,
      'category': category,
      'location': location,
      'description': description,
      'content': description, // Legacy duplicate
      'subjectId': subjectId,
      'sharedWith': sharedWith,
      'attachments': attachments,
      'isUrgent': isUrgent,
      'urgent': isUrgent, // Legacy duplicate
      'isAllDay': isAllDay,
      'endDate': endDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'dateTime': dateTime.toIso8601String(),
      'timestamp': dateTime.millisecondsSinceEpoch, // Long for Java
      'type': 'TASK',
      'programId': programId,
      'calendarEventId': calendarEventId,
      'taskAlerts': [{
        'taskAllDay': isAllDay,
        'taskCategory': category,
      }],
      'taskCategory': category,
      'taskDate': date,
      'taskEndTime': endDate?.toIso8601String(),
      'taskLocation': location,
      'taskRepeat': null,
      'taskRepeatCount': 0,
      'taskRepeatEndDate': null,
      'taskStartTime': null,
      'taskTime': time,
      'taskAllDay': isAllDay,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    DateTime parseDt(dynamic v) {
      if (v == null || v == 0) return DateTime(2020, 1, 1);
      if (v is String) {
        final parsed = DateTime.tryParse(v);
        if (parsed != null) return parsed;
        
        // Manejar formato dd/MM/yyyy
        try {
          final parts = v.split('/');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
        } catch (_) {}
        
        return DateTime(2020, 1, 1);
      }
      if (v is DateTime) return v;
      if (v is int) {
        if (v > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(v);
        return DateTime.fromMillisecondsSinceEpoch(v * 1000);
      }
      try { return (v as dynamic).toDate(); } catch (_) { return DateTime(2020, 1, 1); }
    }

    DateTime? parseDtNullable(dynamic v) {
      if (v == null || v == 0) return null;
      return parseDt(v);
    }

    bool parseBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
      return false;
    }

    final String title = (json['title'] ?? json['titulo'] ?? json['tituloTarea'] ?? 'Sin título').toString();
    final String dateStr = (json['date'] ?? json['fecha'] ?? json['taskDate'] ?? '').toString();
    final String? timeStr = json['time'] ?? json['hora'] ?? json['taskTime'];

    List<String> parseStringList(dynamic v) {
      if (v is List) return List<String>.from(v.map((e) => e.toString()));
      return [];
    }

    return Reminder(
      id: (json['id'] ?? json['docId'] ?? '').toString(),
      author: (json['authorName'] ?? json['author'] ?? 'Anónimo').toString(),
      authorId: json['authorId']?.toString(),
      authorPhotoUrl: json['authorPhotoUrl']?.toString(),
      title: title,
      date: dateStr,
      time: timeStr,
      category: (json['category'] ?? json['categoria'] ?? json['taskCategory'] ?? 'General').toString(),
      location: json['location'] ?? json['lugar'] ?? json['taskLocation'],
      description: (json['description'] ?? json['descripcion'] ?? json['contenido'] ?? json['content']).toString(),
      subjectId: json['subjectId'] as String?,
      sharedWith: parseStringList(json['sharedWith']),
      attachments: parseStringList(json['attachments'] ?? json['imagenes']),
      isUrgent: parseBool(json['isUrgent'] ?? json['urgent'] ?? json['urgente']),
      isAllDay: parseBool(json['isAllDay'] ?? json['allDay'] ?? json['taskAllDay']),
      endDate: parseDtNullable(json['endDate'] ?? json['taskEndTime']),
      isCompleted: parseBool(json['isCompleted'] ?? json['completed'] ?? json['terminada']),
      completedAt: parseDtNullable(json['completedAt']),
      dateTime: parseDt(json['dateTime'] ?? json['timestamp'] ?? json['fecha'] ?? json['date']),
      programId: json['programId'] as String?,
      calendarEventId: json['calendarEventId'] as String?,
    );
  }
}
