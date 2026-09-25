import 'group_comment.dart';

class GroupPoll {
  final String id;
  final String author;
  final String? authorId;
  final String? authorPhotoUrl;
  final String question;
  final String? description;
  final List<String> images; // List of image paths
  final List<PollOption> options;
  final DateTime timestamp;
  final DateTime? expiresAt;
  final Map<String, List<String>> reactions;
  final List<GroupComment> comments;

  GroupPoll({
    required this.id,
    required this.author,
    this.authorId,
    this.authorPhotoUrl,
    required this.question,
    this.description,
    this.images = const [],
    required this.options,
    required this.timestamp,
    this.expiresAt,
    this.reactions = const {},
    this.comments = const [],
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': author,
      'author': author,
      'authorId': authorId ?? '',
      'authorPhotoUrl': authorPhotoUrl ?? '',
      'question': question,
      'title': question, // Legacy duplicate
      'content': question, // Legacy duplicate
      'description': description,
      'images': images,
      'options': options.map((o) => o.toJson()).toList(),
      'pollOptions': options.map((o) => o.text).toList(), // Legacy simple list
      'pollVotes': options.map((o) => o.votedBy).toList(), // Legacy nested list
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': 'POLL',
      'expiresAt': expiresAt?.toIso8601String(),
      'expiryTimestamp': expiresAt?.millisecondsSinceEpoch ?? 0,
      'reactions': reactions,
      'comments': comments.map((c) => c.toJson()).toList(),
      'taskAlerts': [],
    };
  }

  factory GroupPoll.fromJson(Map<String, dynamic> json) {
    DateTime parseTime(dynamic ts) {
      if (ts == null || ts == 0) return DateTime(2020, 1, 1);
      if (ts is String) return DateTime.tryParse(ts) ?? DateTime(2020, 1, 1);
      if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
      try { return (ts as dynamic).toDate(); } catch (_) { return DateTime(2020, 1, 1); }
    }

    // Soporte para estructura legacy: pollOptions (List<String>) y pollVotes (List<List<String>>)
    List<PollOption> options = [];
    if (json['pollOptions'] is List && json['pollOptions'].isNotEmpty) {
      final legacyOptions = json['pollOptions'] as List;
      final legacyVotes = json['pollVotes'] as List?;
      for (int i = 0; i < legacyOptions.length; i++) {
        final List<String> voters = (legacyVotes != null && legacyVotes.length > i && legacyVotes[i] is List)
            ? List<String>.from(legacyVotes[i])
            : [];
        options.add(PollOption(
          text: legacyOptions[i].toString(),
          votes: voters.length,
          votedBy: voters,
        ));
      }
    } else if (json['options'] is List) {
      options = (json['options'] as List)
          .map((o) => PollOption.fromJson(Map<String, dynamic>.from(o as Map)))
          .toList();
    }

    return GroupPoll(
      id: (json['id'] ?? '').toString(),
      author: (json['authorName'] ?? json['author'] ?? 'Anónimo').toString(),
      authorId: json['authorId']?.toString(),
      authorPhotoUrl: json['authorPhotoUrl']?.toString(),
      question: (json['question'] ?? json['titulo'] ?? json['title'] ?? json['content'] ?? '').toString(),
      description: json['description'] ?? json['contenido'],
      images: List<String>.from(json['images'] ?? json['imagenes'] ?? []),
      options: options,
      timestamp: parseTime(json['timestamp'] ?? json['fecha']),
      expiresAt: json['expiryTimestamp'] != null && json['expiryTimestamp'] != 0
          ? parseTime(json['expiryTimestamp'])
          : (json['expiresAt'] != null ? parseTime(json['expiresAt']) : null),
      reactions: (json['reactions'] as Map?)?.map(
        (key, value) => MapEntry(key.toString(), List<String>.from(value is Iterable ? value : [])),
      ) ?? {},
      comments: (json['comments'] as List?)
          ?.where((c) => c is Map)
          .map((c) => GroupComment.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList() ?? [],
    );
  }
}

class PollOption {
  final String text;
  int votes;
  final List<String> votedBy;

  PollOption({
    required this.text,
    this.votes = 0,
    this.votedBy = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'votes': votes,
      'votedBy': votedBy,
    };
  }

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      text: json['text'] as String,
      votes: json['votes'] as int? ?? 0,
      votedBy: List<String>.from(json['votedBy'] ?? []),
    );
  }
}
