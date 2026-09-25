import 'package:flutter/material.dart';

enum RecurrenceFrequency { daily, weekly, monthly, yearly, hourly }

class RecurrenceConfig {
  final RecurrenceFrequency frequency;
  final int interval; // Every N hours/days/weeks/etc.
  final List<int>? daysOfWeek; // 1-7 (Mon-Sun)
  final int? dayOfMonth;
  final DateTime? endDate;
  final int? occurrences;
  final List<TimeOfDay>? timesOfDay; // For multiple times per day

  RecurrenceConfig({
    required this.frequency,
    this.interval = 1,
    this.daysOfWeek,
    this.dayOfMonth,
    this.endDate,
    this.occurrences,
    this.timesOfDay,
  });

  String get humanReadable {
    String base = '';
    switch (frequency) {
      case RecurrenceFrequency.hourly:
        base = 'Cada ${interval == 1 ? '' : interval} hora${interval == 1 ? '' : 's'}';
        break;
      case RecurrenceFrequency.daily:
        base = interval == 1 ? 'Diariamente' : 'Cada $interval días';
        break;
      case RecurrenceFrequency.weekly:
        if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
          final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
          final formattedDays = daysOfWeek!.map((d) {
            final idx = (d >= 1 && d <= 7) ? d - 1 : (d % 7);
            return (idx >= 0 && idx < days.length) ? days[idx] : '';
          }).where((s) => s.isNotEmpty).join(', ');
          base = 'Semanalmente ($formattedDays)';
        } else {
          base = interval == 1 ? 'Semanalmente' : 'Cada $interval semanas';
        }
        break;
      case RecurrenceFrequency.monthly:
        base = interval == 1 ? 'Mensualmente' : 'Cada $interval meses';
        break;
      case RecurrenceFrequency.yearly:
        base = 'Anualmente';
        break;
    }
    
    if (timesOfDay != null && timesOfDay!.isNotEmpty) {
      base += ' [${timesOfDay!.length} veces/día]';
    }
    
    if (endDate != null) {
      base += ' hasta ${endDate!.day}/${endDate!.month}';
    } else if (occurrences != null) {
      base += ' por $occurrences veces';
    }
    
    return base;
  }
}

class RecurringProgram {
  final String id;
  final String title;
  final String category;
  final String? location;
  final String? description;
  final String? subjectId;
  final RecurrenceConfig config;
  final DateTime startDate;
  final bool isUrgent;
  bool isActive;

  RecurringProgram({
    required this.id,
    required this.title,
    required this.category,
    this.location,
    this.description,
    this.subjectId,
    required this.config,
    required this.startDate,
    this.isUrgent = false,
    this.isActive = true,
  });

  RecurringProgram copyWith({
    String? id,
    String? title,
    String? category,
    String? location,
    String? description,
    String? subjectId,
    RecurrenceConfig? config,
    DateTime? startDate,
    bool? isUrgent,
    bool? isActive,
  }) {
    return RecurringProgram(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      location: location ?? this.location,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      config: config ?? this.config,
      startDate: startDate ?? this.startDate,
      isUrgent: isUrgent ?? this.isUrgent,
      isActive: isActive ?? this.isActive,
    );
  }
}
