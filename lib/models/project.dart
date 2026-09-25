enum ProjectStatus { planning, inProgress, completed, onHold, archived }

class Project {
  final String id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final double progress; // 0.0 to 1.0
  final ProjectStatus status;
  final bool isIndependent;
  final String? groupId;
  final List<String> members;
  final List<ProjectPhase> phases;
  final int currentPhaseIndex;

  Project({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    required this.createdAt,
    this.progress = 0.0,
    this.status = ProjectStatus.planning,
    required this.isIndependent,
    this.groupId,
    this.members = const [],
    this.phases = const [],
    this.currentPhaseIndex = 0,
  });

  ProjectPhase? get currentPhase => phases.isNotEmpty && currentPhaseIndex < phases.length 
      ? phases[currentPhaseIndex] 
      : null;

  bool get isArchived => status == ProjectStatus.archived;

  bool get canEditStartDate => DateTime.now().difference(createdAt).inDays < 1;

  List<ProjectTask> get tasks {
    List<ProjectTask> allTasks = [];
    for (var phase in phases) {
      allTasks.addAll(phase.tasks);
    }
    return allTasks;
  }

  Project copyWith({
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    double? progress,
    ProjectStatus? status,
    List<ProjectPhase>? phases,
    int? currentPhaseIndex,
    List<String>? members,
  }) {
    return Project(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      isIndependent: isIndependent,
      groupId: groupId,
      members: members ?? this.members,
      phases: phases ?? this.phases,
      currentPhaseIndex: currentPhaseIndex ?? this.currentPhaseIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'progress': progress,
      'status': status.index,
      'isIndependent': isIndependent,
      'groupId': groupId,
      'members': members,
      'phases': phases.map((p) => p.toJson()).toList(),
      'currentPhaseIndex': currentPhaseIndex,
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    DateTime parseDt(dynamic v) {
      if (v is String) {
        final parsed = DateTime.tryParse(v);
        if (parsed != null) return parsed;
        
        // Manejar formato dd/MM/yyyy por si acaso
        try {
          final parts = v.split('/');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
        } catch (_) {}
        
        return DateTime.now();
      }
      if (v is DateTime) return v;
      if (v != null && v.runtimeType.toString() == 'Timestamp') {
        return (v as dynamic).toDate();
      }
      return DateTime.now();
    }

    bool parseBool(dynamic v, {bool defaultValue = false}) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
      return defaultValue;
    }

    return Project(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startDate: parseDt(json['startDate']),
      endDate: json['endDate'] != null ? parseDt(json['endDate']) : null,
      createdAt: parseDt(json['createdAt']),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      status: ProjectStatus.values[json['status'] as int? ?? 0],
      isIndependent: parseBool(json['isIndependent'], defaultValue: true),
      groupId: json['groupId'] as String?,
      members: List<String>.from(json['members'] ?? []),
      phases: (json['phases'] as List?)
          ?.map((p) => ProjectPhase.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
      currentPhaseIndex: json['currentPhaseIndex'] as int? ?? 0,
    );
  }
}

class ProjectPhase {
  final String id;
  final String title;
  final bool isCompleted;
  final List<ProjectTask> tasks;

  ProjectPhase({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.tasks = const [],
  });

  ProjectPhase copyWith({bool? isCompleted, List<ProjectTask>? tasks}) {
    return ProjectPhase(
      id: id,
      title: title,
      isCompleted: isCompleted ?? this.isCompleted,
      tasks: tasks ?? this.tasks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'tasks': tasks.map((t) => t.toJson()).toList(),
    };
  }

  factory ProjectPhase.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
      return false;
    }

    return ProjectPhase(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: parseBool(json['isCompleted']),
      tasks: (json['tasks'] as List?)
          ?.map((t) => ProjectTask.fromJson(t as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class ProjectTask {
  final String id;
  final String title;
  final bool isCompleted;
  final String? assignedTo; // Username
  final DateTime? dueDate;

  ProjectTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.assignedTo,
    this.dueDate,
  });

  ProjectTask copyWith({bool? isCompleted, String? assignedTo}) {
    return ProjectTask(
      id: id,
      title: title,
      isCompleted: isCompleted ?? this.isCompleted,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'assignedTo': assignedTo,
      'dueDate': dueDate?.toIso8601String(),
    };
  }

  factory ProjectTask.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
      return false;
    }

    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      if (v is DateTime) return v;
      if (v.runtimeType.toString() == 'Timestamp') {
        return (v as dynamic).toDate();
      }
      return null;
    }

    return ProjectTask(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: parseBool(json['isCompleted']),
      assignedTo: json['assignedTo'] as String?,
      dueDate: parseDt(json['dueDate']),
    );
  }
}
