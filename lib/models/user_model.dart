class UserModel {
  final String id;
  final String username;
  final String name;
  final String email;
  final String? photoUrl;
  final int coins;
  final List<String> friends;
  final DateTime createdAt;
  final DateTime? dateOfBirth;
  final String about;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? profileUpdatedAt;

  UserModel({
    required this.id,
    required this.username,
    this.name = '',
    required this.email,
    this.photoUrl,
    this.coins = 0,
    this.friends = const [],
    required this.createdAt,
    this.dateOfBirth,
    this.about = '',
    this.isOnline = false,
    this.lastSeen,
    this.profileUpdatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'coins': coins,
        'friends': friends,
        'createdAt': createdAt.toIso8601String(),
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'about': about,
        'isOnline': isOnline,
        'lastSeen': lastSeen?.toIso8601String(),
        'profileUpdatedAt': profileUpdatedAt?.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        username: json['username'],
        name: json['name'] ?? '',
        email: json['email'],
        photoUrl: json['photoUrl'],
        coins: json['coins'] ?? 0,
        friends: List<String>.from(json['friends'] ?? []),
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        dateOfBirth: json['dateOfBirth'] != null 
            ? DateTime.parse(json['dateOfBirth'])
            : null,
        about: json['about'] ?? '',
        isOnline: json['isOnline'] ?? false,
        lastSeen: json['lastSeen'] != null 
            ? DateTime.parse(json['lastSeen'])
            : null,
        profileUpdatedAt: json['profileUpdatedAt'] != null
            ? DateTime.parse(json['profileUpdatedAt'])
            : null,
      );

  UserModel copyWith({
    String? id,
    String? username,
    String? name,
    String? email,
    String? photoUrl,
    int? coins,
    List<String>? friends,
    DateTime? createdAt,
    DateTime? dateOfBirth,
    String? about,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? profileUpdatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      coins: coins ?? this.coins,
      friends: friends ?? this.friends,
      createdAt: createdAt ?? this.createdAt,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      about: about ?? this.about,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      profileUpdatedAt: profileUpdatedAt ?? this.profileUpdatedAt,
    );
  }
}
