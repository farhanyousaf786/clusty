class UserModel {
  final String id;
  final String email;
  final String? username;
  final String? name;
  final String? photoUrl;
  final String? about;
  final int? dob;
  final int createdAt;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final double rating;
  final int ratingCount;

  UserModel({
    required this.id,
    required this.email,
    this.username,
    this.name,
    this.photoUrl,
    this.about,
    this.dob,
    required this.createdAt,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.rating = 0.0,
    this.ratingCount = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      name: json['name'] as String?,
      photoUrl: json['photoUrl'] as String?,
      about: json['about'] as String?,
      dob: json['dob'] as int?,
      createdAt: json['createdAt'] as int,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      postsCount: json['postsCount'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (username != null) 'username': username,
      if (name != null) 'name': name,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (about != null) 'about': about,
      if (dob != null) 'dob': dob,
      'createdAt': createdAt,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'rating': rating,
      'ratingCount': ratingCount,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? name,
    String? photoUrl,
    String? about,
    int? dob,
    int? createdAt,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    double? rating,
    int? ratingCount,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      about: about ?? this.about,
      dob: dob ?? this.dob,
      createdAt: createdAt ?? this.createdAt,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }
}
