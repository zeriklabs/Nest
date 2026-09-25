import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequest {
  final String id;
  final String fromId;
  final String fromName;
  final String fromAlias;
  final String? fromPhoto;
  final String toId;
  final String status;
  final DateTime timestamp;

  FriendRequest({
    required this.id,
    required this.fromId,
    required this.fromName,
    required this.fromAlias,
    this.fromPhoto,
    required this.toId,
    required this.status,
    required this.timestamp,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] ?? '',
      fromId: json['fromId'] ?? '',
      fromName: json['fromName'] ?? 'Usuario',
      fromAlias: json['fromAlias'] ?? 'nest_user',
      fromPhoto: json['fromPhoto'],
      toId: json['toId'] ?? '',
      status: json['status'] ?? 'pending',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
