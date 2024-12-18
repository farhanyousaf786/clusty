class PostModel {
  final String id;
  final String userId;
  final String username;
  final String? userPhotoUrl;
  final String content;
  final String? imageUrl;
  final bool isMeme;
  final int likes;
  final int comments;
  final int timestamp;

  PostModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userPhotoUrl,
    required this.content,
    this.imageUrl,
    this.isMeme = false,
    required this.likes,
    required this.comments,
    required this.timestamp,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      isMeme: json['isMeme'] as bool? ?? false,
      likes: json['likes'] as int? ?? 0,
      comments: json['comments'] as int? ?? 0,
      timestamp: json['timestamp'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'imageUrl': imageUrl,
      'isMeme': isMeme,
      'likes': likes,
      'comments': comments,
      'timestamp': timestamp,
    };
  }

  PostModel copyWith({
    String? content,
    String? imageUrl,
    bool? isMeme,
    int? likes,
    int? comments,
  }) {
    return PostModel(
      id: id,
      userId: userId,
      username: username,
      userPhotoUrl: userPhotoUrl,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      isMeme: isMeme ?? this.isMeme,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      timestamp: timestamp,
    );
  }
}
