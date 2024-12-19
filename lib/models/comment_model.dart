class CommentModel {
  final String id;
  final String userId;
  final String postId;
  final String content;
  final int timestamp;

  CommentModel({
    required this.id,
    required this.userId,
    required this.postId,
    required this.content,
    required this.timestamp,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    return CommentModel(
      id: id,
      userId: map['userId'] as String,
      postId: map['postId'] as String,
      content: map['content'] as String,
      timestamp: map['timestamp'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'postId': postId,
      'content': content,
      'timestamp': timestamp,
    };
  }
}
