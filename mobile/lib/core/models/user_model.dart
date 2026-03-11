class UserModel {
  final String id;
  final String name;
  final String? phone;
  final String? username;
  final String? avatarUrl;
  final String? bio;
  final bool? isOnline;
  final String? lastSeenAt;

  const UserModel({
    required this.id,
    required this.name,
    this.phone,
    this.username,
    this.avatarUrl,
    this.bio,
    this.isOnline,
    this.lastSeenAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      isOnline: json['isOnline'] as bool?,
      lastSeenAt: json['lastSeenAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'username': username,
    'avatarUrl': avatarUrl,
    'bio': bio,
    'isOnline': isOnline,
    'lastSeenAt': lastSeenAt,
  };

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? username,
    String? avatarUrl,
    String? bio,
    bool? isOnline,
    String? lastSeenAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}
