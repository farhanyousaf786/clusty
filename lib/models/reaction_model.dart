import 'reaction_type.dart';

class ReactionModel {
  final String id;
  final String userId;
  final String postId;
  final ReactionType type;
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
      type: ReactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      timestamp: json['timestamp'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'postId': postId,
      'type': type.toString().split('.').last,
      'timestamp': timestamp,
    };
  }
}
