class TaskModel {
  final String id;
  final String title;
  final String description;
  final int coinReward;
  final DateTime deadline;
  final bool isCompleted;
  final String assignedTo;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.coinReward,
    required this.deadline,
    this.isCompleted = false,
    required this.assignedTo,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'coinReward': coinReward,
        'deadline': deadline.toIso8601String(),
        'isCompleted': isCompleted,
        'assignedTo': assignedTo,
      };

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        coinReward: json['coinReward'],
        deadline: DateTime.parse(json['deadline']),
        isCompleted: json['isCompleted'] ?? false,
        assignedTo: json['assignedTo'],
      );
}
