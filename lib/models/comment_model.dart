class CommentModel {
  final String id;
  final String userId;
  final String postId;
  final String content;
  final int timestamp;
  final String username;
  final String? userPhotoUrl;

  CommentModel({
    required this.id,
    required this.userId,
    required this.postId,
    required this.content,
    required this.timestamp,
    required this.username,
    this.userPhotoUrl,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json, String id) {
    return CommentModel(
      id: id,
      userId: json['userId'] as String,
      postId: json['postId'] as String,
      content: json['content'] as String,
      timestamp: json['timestamp'] as int,
      username: json['username'] as String,
      userPhotoUrl: json['userPhotoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'postId': postId,
      'content': content,
      'timestamp': timestamp,
      'username': username,
      'userPhotoUrl': userPhotoUrl,
    };
  }
}
