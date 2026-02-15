class User {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  final String? bio;
  final int totalLikes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? followerCount;
  final int? followingCount;
  final int? answerCount;
  final bool? isFollowing;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    this.bio,
    required this.totalLikes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.followerCount,
    this.followingCount,
    this.answerCount,
    this.isFollowing,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      bio: json['bio'] as String?,
      totalLikes: json['total_likes'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      followerCount: json['follower_count'] as int?,
      followingCount: json['following_count'] as int?,
      answerCount: json['answer_count'] as int?,
      isFollowing: json['is_following'] as bool?,
    );
  }

  String get avatarInitial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  String get displayName => name.isNotEmpty ? '@$name' : '@unknown';

  User copyWith({
    int? followerCount,
    int? followingCount,
    bool? isFollowing,
  }) {
    return User(
      id: id,
      email: email,
      name: name,
      avatar: avatar,
      bio: bio,
      totalLikes: totalLikes,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      answerCount: answerCount,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}
