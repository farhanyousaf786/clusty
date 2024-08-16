import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  String username;
  String userImageUrl;
  final String caption;
  final String imageUrl;
  final String description;
  final String mood;
  final List<String> tags;
  final Timestamp createdAt;
  List<String> likes;

  Post({
    required this.id,
    required this.userId,
    this.username = '',
    this.userImageUrl = '',
    required this.caption,
    required this.imageUrl,
    required this.description,
    required this.mood,
    required this.tags,
    required this.createdAt,
    this.likes = const [],
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      userId: data['userId'],
      caption: data['caption'],
      imageUrl: data['imageUrl'],
      description: data['description'],
      mood: data['mood'],
      tags: List<String>.from(data['tags']),
      createdAt: data['createdAt'],
      likes: List<String>.from(data['likes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'caption': caption,
      'imageUrl': imageUrl,
      'description': description,
      'mood': mood,
      'tags': tags,
      'createdAt': createdAt,
      'likes': likes,
    };
  }
}
