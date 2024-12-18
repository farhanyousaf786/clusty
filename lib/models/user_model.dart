class UserModel {
  final String id;
  final String email;
  final String username;
  final String? name;
  final String? photoUrl;
  final int createdAt;
  final int? dob;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final String? about;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.name,
    this.photoUrl,
    required this.createdAt,
    this.dob,
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
      name: json['name'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: json['createdAt'] as int,
      dob: json['dob'] as int?,
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
      'name': name,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'dob': dob,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'about': about,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? name,
    String? photoUrl,
    int? createdAt,
    int? dob,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    String? about,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      dob: dob ?? this.dob,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      about: about ?? this.about,
    );
  }
}
