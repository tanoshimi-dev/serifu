import 'user.dart';

class Answer {
  final String id;
  final String quizId;
  final String userId;
  final User? user;
  final String content;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool? isLiked;

  const Answer({
    required this.id,
    required this.quizId,
    required this.userId,
    this.user,
    required this.content,
    required this.likeCount,
    required this.commentCount,
    required this.viewCount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.isLiked,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'] as String,
      quizId: json['quiz_id'] as String,
      userId: json['user_id'] as String,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      content: json['content'] as String,
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      viewCount: json['view_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isLiked: json['is_liked'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'quiz_id': quizId,
        'content': content,
      };

  Answer copyWith({
    int? likeCount,
    bool? isLiked,
  }) {
    return Answer(
      id: id,
      quizId: quizId,
      userId: userId,
      user: user,
      content: content,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount,
      viewCount: viewCount,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

class Comment {
  final String id;
  final String answerId;
  final String userId;
  final User? user;
  final String content;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Comment({
    required this.id,
    required this.answerId,
    required this.userId,
    this.user,
    required this.content,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      answerId: json['answer_id'] as String,
      userId: json['user_id'] as String,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      content: json['content'] as String,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
