enum MilestoneStatus { NotStarted, InProgress, Delayed, Completed }
enum TaskStatus { NotStarted, InProgress, Delayed, Completed }
enum MaterialStatus { Required, Ordered, Delivered }

class Milestone {
  final String milestoneId;
  final String projectId;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime dueDate;
  final MilestoneStatus status;

  Milestone({
    required this.milestoneId,
    required this.projectId,
    required this.name,
    required this.description,
    required this.startDate,
    required this.dueDate,
    required this.status,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      milestoneId: json['milestoneId'] ?? '',
      projectId: json['projectId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      dueDate: DateTime.tryParse(json['dueDate'] ?? '') ?? DateTime.now(),
      status: _parseMilestoneStatus(json['status']),
    );
  }

  static MilestoneStatus _parseMilestoneStatus(String? status) {
    switch (status) {
      case 'InProgress':
        return MilestoneStatus.InProgress;
      case 'Delayed':
        return MilestoneStatus.Delayed;
      case 'Completed':
        return MilestoneStatus.Completed;
      default:
        return MilestoneStatus.NotStarted;
    }
  }
}

class Task {
  final String taskId;
  final String milestoneId;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime dueDate;
  final TaskStatus status;
  final int cascadedDelay;

  Task({
    required this.taskId,
    required this.milestoneId,
    required this.name,
    required this.description,
    required this.startDate,
    required this.dueDate,
    required this.status,
    required this.cascadedDelay,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskId: json['taskId'] ?? '',
      milestoneId: json['milestoneId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      dueDate: DateTime.tryParse(json['dueDate'] ?? '') ?? DateTime.now(),
      status: _parseTaskStatus(json['status']),
      cascadedDelay: json['cascadedDelay'] ?? 0,
    );
  }

  static TaskStatus _parseTaskStatus(String? status) {
    switch (status) {
      case 'InProgress':
        return TaskStatus.InProgress;
      case 'Delayed':
        return TaskStatus.Delayed;
      case 'Completed':
        return TaskStatus.Completed;
      default:
        return TaskStatus.NotStarted;
    }
  }
}

class MaterialItem {
  final String materialId;
  final String projectId;
  final String name;
  final String description;
  final int quantity;
  final String unit;
  final MaterialStatus status;

  MaterialItem({
    required this.materialId,
    required this.projectId,
    required this.name,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.status,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      materialId: json['materialId'] ?? '',
      projectId: json['projectId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 0,
      unit: json['unit'] ?? '',
      status: _parseMaterialStatus(json['status']),
    );
  }

  static MaterialStatus _parseMaterialStatus(String? status) {
    switch (status) {
      case 'Ordered':
        return MaterialStatus.Ordered;
      case 'Delivered':
        return MaterialStatus.Delivered;
      default:
        return MaterialStatus.Required;
    }
  }
}

class TaskDependency {
  final String dependencyId;
  final String taskId;
  final String prerequisiteTaskId;

  TaskDependency({
    required this.dependencyId,
    required this.taskId,
    required this.prerequisiteTaskId,
  });

  factory TaskDependency.fromJson(Map<String, dynamic> json) {
    return TaskDependency(
      dependencyId: json['dependencyId'] ?? '',
      taskId: json['taskId'] ?? '',
      prerequisiteTaskId: json['prerequisiteTaskId'] ?? '',
    );
  }
}

class ProgressPhoto {
  final String photoId;
  final String projectId;
  final String? milestoneId;
  final String? taskId;
  final String fileUrl;
  final String? caption;
  final DateTime uploadedAt;

  ProgressPhoto({
    required this.photoId,
    required this.projectId,
    this.milestoneId,
    this.taskId,
    required this.fileUrl,
    this.caption,
    required this.uploadedAt,
  });

  factory ProgressPhoto.fromJson(Map<String, dynamic> json) {
    return ProgressPhoto(
      photoId: json['photoId'] ?? '',
      projectId: json['projectId'] ?? '',
      milestoneId: json['milestoneId'],
      taskId: json['taskId'],
      fileUrl: json['fileUrl'] ?? '',
      caption: json['caption'],
      uploadedAt: DateTime.tryParse(json['uploadedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class TimelineEvent {
  final String eventId;
  final String eventType;
  final String title;
  final String? description;
  final DateTime timestamp;

  TimelineEvent({
    required this.eventId,
    required this.eventType,
    required this.title,
    this.description,
    required this.timestamp,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      eventId: json['eventId'] ?? '',
      eventType: json['eventType'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

class ProjectAnalytics {
  final double overallProgress;
  final int totalTasks;
  final int completedTasks;
  final int delayedTasks;
  final int totalMilestones;
  final int completedMilestones;
  final int delayedMilestones;

  ProjectAnalytics({
    required this.overallProgress,
    required this.totalTasks,
    required this.completedTasks,
    required this.delayedTasks,
    required this.totalMilestones,
    required this.completedMilestones,
    required this.delayedMilestones,
  });

  factory ProjectAnalytics.fromJson(Map<String, dynamic> json) {
    return ProjectAnalytics(
      overallProgress: (json['overallProgress'] ?? 0.0).toDouble(),
      totalTasks: json['tasks']?['total'] ?? 0,
      completedTasks: json['tasks']?['completed'] ?? 0,
      delayedTasks: json['tasks']?['delayed'] ?? 0,
      totalMilestones: json['milestones']?['total'] ?? 0,
      completedMilestones: json['milestones']?['completed'] ?? 0,
      delayedMilestones: json['milestones']?['delayed'] ?? 0,
    );
  }
}
