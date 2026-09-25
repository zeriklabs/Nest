import 'package:flutter/material.dart';

class Subject {
  final String id;
  final String name;
  final String? group;
  final String? teacher;
  final String? building;
  final Color color;
  final List<SubjectSchedule> schedules;
  final List<String> discardedDates;
  final Map<String, dynamic> overrides; // Almacena descartes y desplazamientos por fecha/hora

  Subject({
    required this.id,
    required this.name,
    this.group,
    this.teacher,
    this.building,
    required this.color,
    required this.schedules,
    this.discardedDates = const [],
    this.overrides = const {},
  });

  Subject copyWith({
    String? id,
    String? name,
    String? group,
    String? teacher,
    String? building,
    Color? color,
    List<SubjectSchedule>? schedules,
    List<String>? discardedDates,
    Map<String, dynamic>? overrides,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      group: group ?? this.group,
      teacher: teacher ?? this.teacher,
      building: building ?? this.building,
      color: color ?? this.color,
      schedules: schedules ?? this.schedules,
      discardedDates: discardedDates ?? this.discardedDates,
      overrides: overrides ?? this.overrides,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'subject': name, // Java: subject
      'name': name,    // Flutter fallback
      'groupName': group, // Java: groupName
      'group': group,     // Flutter fallback
      'teacher': teacher,
      'building': building,
      'color': '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}', // Java: Hex String #RRGGBB
      'schedules': schedules.map((s) => s.toJson()).toList(),
      'discardedDates': discardedDates,
      'overrides': overrides,
    };

    // Para compatibilidad con el formato plano de Java (un doc por clase)
    if (schedules.isNotEmpty) {
      final first = schedules.first;
      data['day'] = first.day;
      data['startTime'] = first.startTime.format24();
      data['endTime'] = first.endTime.format24();
      data['classroom'] = first.room; // Usamos el salón de la primera sesión
      data['room'] = first.room;
    }

    return data;
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    // 1. Si tiene la lista de horarios y NO está vacía, usamos el formato jerárquico nuevo
    if (json.containsKey('schedules') && json['schedules'] is List && (json['schedules'] as List).isNotEmpty) {
      return _fromNewJson(json);
    }
    
    // 2. Si no tiene schedules o está vacía, verificamos si es el formato plano antiguo
    if (json.containsKey('day') || 
        json.containsKey('subject') || 
        json.containsKey('name') ||
        json.containsKey('classroom') || 
        json.containsKey('room') ||
        json.containsKey('startTime')) {
      return _fromOldJson(json);
    }

    // 3. Fallback final
    return _fromNewJson(json);
  }

  static Subject _fromNewJson(Map<String, dynamic> json) {
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

    return Subject(
      id: (json['id'] ?? json['docId'] ?? (json['subject'] ?? json['name'] ?? 'unnamed').toString().hashCode.toString()).toString(),
      name: (json['name'] ?? json['subject'] ?? 'Sin nombre').toString(),
      group: (json['group'] ?? json['groupName'])?.toString(),
      teacher: json['teacher'] as String?,
      building: json['building'] as String?,
      color: parseColor(json['color']),
      schedules: json['schedules'] != null && json['schedules'] is List
          ? (json['schedules'] as List).map((s) {
              if (s is Map) {
                final Map<String, dynamic> sessionData = Map<String, dynamic>.from(s);
                // Si el salón viene en la raíz (formato viejo) y la sesión no tiene, lo inyectamos
                if (sessionData['classroom'] == null && sessionData['room'] == null) {
                  sessionData['room'] = json['classroom'] ?? json['room'];
                }
                return SubjectSchedule.fromJson(sessionData);
              }
              return null;
            }).whereType<SubjectSchedule>().toList()
          : [],
      discardedDates: json['discardedDates'] != null
          ? List<String>.from(json['discardedDates'])
          : [],
      overrides: json['overrides'] != null
          ? Map<String, dynamic>.from(json['overrides'])
          : (json['shiftedDates'] != null ? Map<String, dynamic>.from(json['shiftedDates']) : {}),
    );
  }

  static Subject _fromOldJson(Map<String, dynamic> json) {
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

    final String subjectId = (json['id'] ?? json['docId'] ?? (json['subject'] ?? json['name'] ?? 'unnamed').toString().hashCode.toString()).toString();
    
    return Subject(
      id: subjectId,
      name: (json['subject'] as String? ?? json['name'] as String? ?? 'Materia sin nombre').trim(),
      group: (json['group'] ?? json['groupName'])?.toString(),
      teacher: json['teacher'] as String?,
      building: json['building'] as String?,
      color: parseColor(json['color']),
      schedules: [
        SubjectSchedule.fromJson({
          'id': '${subjectId}_session',
          'day': json['day'],
          'startTime': json['startTime'],
          'endTime': json['endTime'],
          'classroom': json['classroom'] ?? json['room'] ?? 'S/N',
        })
      ],
      discardedDates: json['discardedDates'] != null
          ? List<String>.from(json['discardedDates'])
          : [],
      overrides: json['overrides'] != null
          ? Map<String, dynamic>.from(json['overrides'])
          : (json['shiftedDates'] != null ? Map<String, dynamic>.from(json['shiftedDates']) : {}),
    );
  }
}

class SubjectSchedule {
  final String id;
  final String day;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? room;

  SubjectSchedule({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.room,
  });

  String get timeRange => '${startTime.format24()} - ${endTime.format24()}';

  double get startHourDouble => startTime.hour + startTime.minute / 60.0;
  double get endHourDouble => endTime.hour + endTime.minute / 60.0;
  double get durationHours => endHourDouble - startHourDouble;

  bool matchesDate(DateTime date) {
    const daysList = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return day.toLowerCase() == daysList[date.weekday - 1].toLowerCase();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day': day,
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
      'startTime': startTime.format24(),
      'endTime': endTime.format24(),
      'classroom': room,
    };
  }

  factory SubjectSchedule.fromJson(Map<String, dynamic> json) {
    TimeOfDay parseTime(dynamic h, dynamic m, dynamic fallbackStr) {
      try {
        if (h != null && m != null) {
          return TimeOfDay(hour: (h as num).toInt(), minute: (m as num).toInt());
        }
        if (fallbackStr is String && fallbackStr.contains(':')) {
          final lowerStr = fallbackStr.toLowerCase();
          final parts = fallbackStr.split(':');
          int hour = int.tryParse(parts[0]) ?? 8;
          int minute = 0;
          if (parts.length > 1) {
            final minPart = parts[1].split(' ')[0].replaceAll(RegExp(r'[^0-9]'), '');
            minute = int.tryParse(minPart) ?? 0;
          }
          if (lowerStr.contains('pm') && hour < 12) hour += 12;
          if (lowerStr.contains('am') && hour == 12) hour = 0;
          return TimeOfDay(hour: hour % 24, minute: minute % 60);
        }
      } catch (_) {}
      return const TimeOfDay(hour: 8, minute: 0);
    }

    String normalizeDay(dynamic day) {
      if (day == null) return 'Lunes';
      if (day is int) {
        // Soporte para Dart (1=Lun...7=Dom) y Java (1=Dom, 2=Lun...7=Sáb)
        // Heurística: Si detectamos Java, convertimos. 
        // Java: 1(Dom), 2(Lun), 3(Mar), 4(Mié), 5(Jue), 6(Vie), 7(Sáb)
        // Dart: 1(Lun), 2(Mar), 3(Mié), 4(Jue), 5(Vie), 6(Sáb), 7(Dom)
        
        // Asumimos que si viene de una versión vieja (Java), 1 es Domingo.
        const javaDays = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
        
        if (day >= 1 && day <= 7) {
          // Si el JSON parece ser de formato antiguo, usamos javaDays
          return javaDays[day - 1]; 
        }
        return 'Lunes';
      }
      final d = day.toString().toLowerCase();
      if (d.startsWith('lun') || d == 'monday' || d == 'mon') return 'Lunes';
      if (d.startsWith('mar') || d == 'tuesday' || d == 'tue') return 'Martes';
      if (d.startsWith('mie') || d.startsWith('mié') || d == 'wednesday' || d == 'wed') return 'Miércoles';
      if (d.startsWith('jue') || d == 'thursday' || d == 'thu') return 'Jueves';
      if (d.startsWith('vie') || d == 'friday' || d == 'fri') return 'Viernes';
      if (d.startsWith('sab') || d.startsWith('sáb') || d == 'saturday' || d == 'sat') return 'Sábado';
      if (d.startsWith('dom') || d == 'sunday' || d == 'sun') return 'Domingo';
      return day.toString();
    }

    return SubjectSchedule(
      id: (json['id'] ?? json['sessionId'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
      day: normalizeDay(json['day']),
      startTime: parseTime(json['startHour'], json['startMinute'], json['startTime']),
      endTime: parseTime(json['endHour'], json['endMinute'], json['endTime']),
      room: (json['classroom'] ?? json['room'])?.toString(),
    );
  }
}

extension TimeOfDayExtension on TimeOfDay {
  String format24() {
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }
}

class ScheduleOverride {
  final String subjectId;
  final DateTime date;
  final TimeOfDay originalStartTime;
  final double offsetHours;
  final double? customDurationHours;
  final bool isDiscarded;

  ScheduleOverride({
    required this.subjectId,
    required this.date,
    required this.originalStartTime,
    this.offsetHours = 0.0,
    this.customDurationHours,
    this.isDiscarded = false,
  });
}

class ClassInstance {
  final Subject subject;
  final SubjectSchedule schedule;
  final DateTime date;
  final double offsetHours;
  final double? customDurationHours;
  final bool isDiscarded;

  ClassInstance({
    required this.subject,
    required this.schedule,
    required this.date,
    this.offsetHours = 0.0,
    this.customDurationHours,
    this.isDiscarded = false,
  });

  double get startHour => schedule.startHourDouble + offsetHours;
  double get endHour => customDurationHours != null 
      ? startHour + customDurationHours! 
      : schedule.endHourDouble + offsetHours;

  String get formattedTime {
    final start = _doubleToTimeOfDay(startHour);
    final end = _doubleToTimeOfDay(endHour);
    return '${start.format24()} - ${end.format24()}';
  }

  static TimeOfDay _doubleToTimeOfDay(double value) {
    int hour = value.floor();
    int minute = ((value - hour) * 60).round();
    if (minute == 60) {
      hour++;
      minute = 0;
    }
    return TimeOfDay(hour: hour % 24, minute: minute);
  }
}

class TimeSlot {
  final double startHour;
  final double endHour;

  TimeSlot({required this.startHour, required this.endHour});

  String get formattedRange {
    final start = ClassInstance._doubleToTimeOfDay(startHour);
    final end = ClassInstance._doubleToTimeOfDay(endHour);
    return '${start.format24()} - ${end.format24()}';
  }
}
