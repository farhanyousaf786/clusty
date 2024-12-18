class ReactionModel {
  final String id;
  final String userId;
  final String postId;
  final String type;
  final int timestamp;

  ReactionModel({
    required this.id,
    required this.userId,
    required this.postId,
    required this.type,
    required this.timestamp,
  });

  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    return ReactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      postId: json['postId'] as String,
      type: json['type'] as String,
      timestamp: json['timestamp'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'postId': postId,
      'type': type,
      'timestamp': timestamp,
    };
  }
}
