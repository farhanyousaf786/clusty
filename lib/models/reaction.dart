enum ReactionType {
  like,
  // Add more reaction types as needed
}

class Reaction {
  final String id;
  final String userId;
  final String postId;
  final ReactionType type;
  final DateTime createdAt;

  Reaction({
    required this.id,
    required this.userId,
    required this.postId,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'postId': postId,
      'type': type.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      postId: json['postId'] as String,
      type: ReactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
