import 'package:device_calendar/device_calendar.dart' hide Reminder;
import 'package:flutter/foundation.dart';
import '../models/reminder.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal() {
    tz.initializeTimeZones();
  }

  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
      permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
    }
    return permissionsGranted.isSuccess && permissionsGranted.data!;
  }

  Future<List<Calendar>> getAvailableCalendars() async {
    if (kIsWeb) return [];
    try {
      if (!await requestPermissions()) return [];
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess && calendarsResult.data != null) {
        // Solo retornamos calendarios donde el usuario tenga permiso de escritura
        return calendarsResult.data!.where((c) => c.isReadOnly == false).toList();
      }
    } catch (e) {
      debugPrint("Error retrieving calendars: $e");
    }
    return [];
  }

  Future<String?> syncReminder(Reminder reminder, {String? targetCalendarId}) async {
    if (kIsWeb) return null;
    try {
      if (!await requestPermissions()) return null;

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data == null || calendarsResult.data!.isEmpty) {
        return null;
      }

      Calendar? calendar;
      if (targetCalendarId != null && targetCalendarId.isNotEmpty) {
        calendar = calendarsResult.data!.firstWhere(
          (c) => c.id == targetCalendarId,
          orElse: () => calendarsResult.data!.firstWhere(
            (c) => c.isDefault ?? false,
            orElse: () => calendarsResult.data!.first,
          ),
        );
      } else {
        calendar = calendarsResult.data!.firstWhere(
          (c) => c.isDefault ?? false,
          orElse: () => calendarsResult.data!.first,
        );
      }

      final start = tz.TZDateTime.from(reminder.dateTime, tz.local);
      final end = reminder.isAllDay 
          ? start.add(const Duration(days: 1))
          : start.add(const Duration(hours: 1));

      final event = Event(
        calendar.id,
        title: reminder.title,
        start: start,
        end: end,
        description: reminder.description,
        location: reminder.location,
        allDay: reminder.isAllDay,
      );

      final result = await _deviceCalendarPlugin.createOrUpdateEvent(event);
      if (result != null && result.isSuccess) {
        return result.data;
      }
    } catch (e) {
      debugPrint("Error syncing reminder to calendar: $e");
    }
    return null;
  }

  Future<bool> deleteEvent(String? eventId) async {
    if (kIsWeb || eventId == null) return false;
    try {
      if (!await requestPermissions()) return false;

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data == null) return false;

      for (var calendar in calendarsResult.data!) {
        final result = await _deviceCalendarPlugin.deleteEvent(calendar.id, eventId);
        if (result.isSuccess && result.data!) return true;
      }
    } catch (e) {
      debugPrint("Error deleting event from calendar: $e");
    }
    return false;
  }
}
