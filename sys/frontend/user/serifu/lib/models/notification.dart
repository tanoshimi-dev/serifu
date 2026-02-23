import 'user.dart';

class AppNotification {
  final String id;
  final String userId;
  final String actorId;
  final User? actor;
  final String type; // like, comment, follow
  final String targetType; // answer, user
  final String targetId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.actorId,
    this.actor,
    required this.type,
    required this.targetType,
    required this.targetId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      actorId: json['actor_id'] as String,
      actor: json['actor'] != null
          ? User.fromJson(json['actor'] as Map<String, dynamic>)
          : null,
      type: json['type'] as String,
      targetType: json['target_type'] as String? ?? '',
      targetId: json['target_id'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get message {
    final actorName = actor?.name ?? 'Someone';
    switch (type) {
      case 'like':
        return '$actorName liked your answer';
      case 'comment':
        return '$actorName commented on your answer';
      case 'follow':
        return '$actorName started following you';
      default:
        return '$actorName interacted with you';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}
