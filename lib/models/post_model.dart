class PostModel {
  final String id;
  final String userId;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final List<String> likes;
  final List<String> comments;

  PostModel({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.likes = const [],
    this.comments = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'content': content,
        'imageUrl': imageUrl,
        'createdAt': createdAt.toIso8601String(),
        'likes': likes,
        'comments': comments,
      };

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        id: json['id'],
        userId: json['userId'],
        content: json['content'],
        imageUrl: json['imageUrl'],
        createdAt: DateTime.parse(json['createdAt']),
        likes: List<String>.from(json['likes'] ?? []),
        comments: List<String>.from(json['comments'] ?? []),
      );
}
