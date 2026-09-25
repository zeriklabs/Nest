class Contact {
  final String id;
  final String nestId;
  final String name;
  final String alias;
  final String? photoUrl;
  final DateTime addedAt;

  Contact({
    required this.id,
    required this.nestId,
    required this.name,
    required this.alias,
    this.photoUrl,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userIdentifier': nestId,
      'username': name,
      'alias': alias,
      'photoUrl': photoUrl,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] ?? json['uid'] ?? '',
      nestId: json['userIdentifier'] ?? json['useridentifier'] ?? '',
      name: json['username'] ?? json['name'] ?? 'Usuario',
      alias: json['alias'] ?? 'nest_user',
      photoUrl: json['photoUrl'],
      addedAt: json['addedAt'] != null ? DateTime.parse(json['addedAt']) : DateTime.now(),
    );
  }

  Contact copyWith({
    String? id,
    String? nestId,
    String? name,
    String? alias,
    String? photoUrl,
    DateTime? addedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      nestId: nestId ?? this.nestId,
      name: name ?? this.name,
      alias: alias ?? this.alias,
      photoUrl: photoUrl ?? this.photoUrl,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
