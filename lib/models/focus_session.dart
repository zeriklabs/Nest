import 'group_comment.dart';

enum FocusSessionStatus { idle, focusing, shortBreak, longBreak }

class FocusSession {
  final String id;
  final String title;
  final String? groupId; 
  final String creatorId;
  final FocusSessionStatus status;
  final DateTime? startTime;
  final int focusDuration; // minutes
  final int breakDuration; // minutes
  final List<String> participants;
  final List<String> invitedUsers;
  final List<GroupComment> chat;
  final DateTime? scheduledFor;
  final bool isPrivate;
  final bool silenceNotifications;
  final bool isStrictMode;
  final bool useRingtone;
  final List<String> leaveRequests;
  final String? exitKey; // The random key for the host
  final DateTime? keyAppearanceTime; // When the key will be revealed

  FocusSession({
    required this.id,
    required this.title,
    this.groupId,
    required this.creatorId,
    this.status = FocusSessionStatus.idle,
    this.startTime,
    this.focusDuration = 25,
    this.breakDuration = 5,
    this.participants = const [],
    this.invitedUsers = const [],
    this.chat = const [],
    this.scheduledFor,
    this.isPrivate = false,
    this.silenceNotifications = false,
    this.isStrictMode = false,
    this.useRingtone = false,
    this.leaveRequests = const [],
    this.exitKey,
    this.keyAppearanceTime,
  });

  bool get isActive => status != FocusSessionStatus.idle;

  FocusSession copyWith({
    FocusSessionStatus? status,
    DateTime? startTime,
    List<String>? participants,
    List<String>? invitedUsers,
    List<GroupComment>? chat,
    bool? silenceNotifications,
    bool? isStrictMode,
    bool? useRingtone,
    List<String>? leaveRequests,
    String? exitKey,
    DateTime? keyAppearanceTime,
  }) {
    return FocusSession(
      id: id,
      title: title,
      groupId: groupId,
      creatorId: creatorId,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      focusDuration: focusDuration,
      breakDuration: breakDuration,
      participants: participants ?? this.participants,
      invitedUsers: invitedUsers ?? this.invitedUsers,
      chat: chat ?? this.chat,
      scheduledFor: scheduledFor,
      isPrivate: isPrivate,
      silenceNotifications: silenceNotifications ?? this.silenceNotifications,
      isStrictMode: isStrictMode ?? this.isStrictMode,
      useRingtone: useRingtone ?? this.useRingtone,
      leaveRequests: leaveRequests ?? this.leaveRequests,
      exitKey: exitKey ?? this.exitKey,
      keyAppearanceTime: keyAppearanceTime ?? this.keyAppearanceTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'groupId': groupId,
      'creatorId': creatorId,
      'status': status.index,
      'startTime': startTime?.toIso8601String(),
      'focusDuration': focusDuration,
      'breakDuration': breakDuration,
      'participants': participants,
      'invitedUsers': invitedUsers,
      'chat': chat.map((c) => c.toJson()).toList(),
      'scheduledFor': scheduledFor?.toIso8601String(),
      'isPrivate': isPrivate,
      'silenceNotifications': silenceNotifications,
      'isStrictMode': isStrictMode,
      'useRingtone': useRingtone,
      'leaveRequests': leaveRequests,
      'exitKey': exitKey,
      'keyAppearanceTime': keyAppearanceTime?.toIso8601String(),
    };
  }

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] as String,
      title: json['title'] as String,
      groupId: json['groupId'] as String?,
      creatorId: json['creatorId'] as String,
      status: FocusSessionStatus.values[json['status'] as int? ?? 0],
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime'] as String) : null,
      focusDuration: json['focusDuration'] as int? ?? 25,
      breakDuration: json['breakDuration'] as int? ?? 5,
      participants: List<String>.from(json['participants'] ?? []),
      invitedUsers: List<String>.from(json['invitedUsers'] ?? []),
      chat: (json['chat'] as List?)
          ?.map((c) => GroupComment.fromJson(c as Map<String, dynamic>))
          .toList() ?? [],
      scheduledFor: json['scheduledFor'] != null ? DateTime.parse(json['scheduledFor'] as String) : null,
      isPrivate: json['isPrivate'] as bool? ?? false,
      silenceNotifications: json['silenceNotifications'] as bool? ?? false,
      isStrictMode: json['isStrictMode'] as bool? ?? false,
      useRingtone: json['useRingtone'] as bool? ?? false,
      leaveRequests: List<String>.from(json['leaveRequests'] ?? []),
      exitKey: json['exitKey'] as String?,
      keyAppearanceTime: json['keyAppearanceTime'] != null ? DateTime.parse(json['keyAppearanceTime'] as String) : null,
    );
  }
}
