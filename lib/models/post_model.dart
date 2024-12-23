import 'package:flutter/material.dart';

enum PostCategory {
  meme,
  advice,
  casual,
  romantic,
  hopeful,
  heartbroken,
  other;

  String get displayName {
    switch (this) {
      case PostCategory.meme:
        return 'Meme';
      case PostCategory.advice:
        return 'Advice';
      case PostCategory.casual:
        return 'Casual';
      case PostCategory.romantic:
        return 'Romantic';
      case PostCategory.hopeful:
        return 'Hopeful';
      case PostCategory.heartbroken:
        return 'Heartbroken';
      case PostCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case PostCategory.meme:
        return Icons.emoji_emotions;
      case PostCategory.advice:
        return Icons.lightbulb;
      case PostCategory.casual:
        return Icons.chat_bubble;
      case PostCategory.romantic:
        return Icons.favorite;
      case PostCategory.hopeful:
        return Icons.star;
      case PostCategory.heartbroken:
        return Icons.heart_broken;
      case PostCategory.other:
        return Icons.category;
    }
  }
}

class PostModel {
  final String id;
  final String userId;
  final String username;
  final String? userPhotoUrl;
  final String content;
  final String? imageUrl;
  final bool isMeme;
  final int timestamp;
  final PostCategory category;
  final bool isHidden;
  final int comments;
  final int likes;

  PostModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userPhotoUrl,
    required this.content,
    this.imageUrl,
    required this.isMeme,
    required this.timestamp,
    required this.category,
    this.isHidden = false,
    this.comments = 0,
    this.likes = 0,
  });

  PostModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? userPhotoUrl,
    String? content,
    String? imageUrl,
    bool? isMeme,
    int? timestamp,
    PostCategory? category,
    bool? isHidden,
    int? comments,
    int? likes,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      isMeme: isMeme ?? this.isMeme,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      isHidden: isHidden ?? this.isHidden,
      comments: comments ?? this.comments,
      likes: likes ?? this.likes,
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
      'timestamp': timestamp,
      'category': category.name,
      'isHidden': isHidden,
      'comments': comments,
      'likes': likes,
    };
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      isMeme: json['isMeme'] as bool,
      timestamp: json['timestamp'] as int,
      category: PostCategory.values.firstWhere(
        (e) => e.name == (json['category'] as String? ?? PostCategory.casual.name),
        orElse: () => PostCategory.casual,
      ),
      isHidden: json['isHidden'] as bool? ?? false,
      comments: json['comments'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
    );
  }
}
