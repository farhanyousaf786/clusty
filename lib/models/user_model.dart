class UserModel {
  final String id;
  final String email;
  final String username;
  final String? photoUrl;
  final int createdAt;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final String? about;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.photoUrl,
    required this.createdAt,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    this.about,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      photoUrl: json['photoUrl'] as String?,
      createdAt: json['createdAt'] as int,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      postsCount: json['postsCount'] as int? ?? 0,
      about: json['about'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'about': about,
    };
  }

  UserModel copyWith({
    String? username,
    String? photoUrl,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    String? about,
  }) {
    return UserModel(
      id: id,
      email: email,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      about: about ?? this.about,
    );
  }
}
