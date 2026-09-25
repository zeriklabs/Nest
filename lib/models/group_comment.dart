class GroupComment {
  final String id;
  final String author;
  final String text;
  final DateTime timestamp;

  GroupComment({
    required this.id,
    required this.author,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GroupComment.fromJson(Map<String, dynamic> json) {
    return GroupComment(
      id: json['id'] as String,
      author: json['author'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
