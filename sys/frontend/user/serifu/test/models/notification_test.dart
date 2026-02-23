import 'package:flutter_test/flutter_test.dart';
import 'package:serifu/models/notification.dart';

void main() {
  group('AppNotification.fromJson', () {
    test('parses full fields with nested actor', () {
      final json = {
        'id': 'n1',
        'user_id': 'u1',
        'actor_id': 'u2',
        'actor': {
          'id': 'u2',
          'name': 'Alice',
          'created_at': '2024-01-01T00:00:00.000Z',
          'updated_at': '2024-01-01T00:00:00.000Z',
        },
        'type': 'like',
        'target_type': 'answer',
        'target_id': 'a1',
        'is_read': false,
        'created_at': '2024-06-01T12:00:00.000Z',
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.id, 'n1');
      expect(notif.userId, 'u1');
      expect(notif.actorId, 'u2');
      expect(notif.actor, isNotNull);
      expect(notif.actor!.name, 'Alice');
      expect(notif.type, 'like');
      expect(notif.targetType, 'answer');
      expect(notif.targetId, 'a1');
      expect(notif.isRead, false);
    });

    test('parses with null actor and defaults', () {
      final json = {
        'id': 'n2',
        'user_id': 'u1',
        'actor_id': 'u3',
        'type': 'follow',
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.actor, isNull);
      expect(notif.targetType, '');
      expect(notif.targetId, '');
      expect(notif.isRead, false);
    });
  });

  group('AppNotification.message', () {
    test('returns liked message', () {
      final notif = _makeNotification(type: 'like', actorName: 'Alice');
      expect(notif.message, 'Alice liked your answer');
    });

    test('returns commented message', () {
      final notif = _makeNotification(type: 'comment', actorName: 'Bob');
      expect(notif.message, 'Bob commented on your answer');
    });

    test('returns follow message', () {
      final notif = _makeNotification(type: 'follow', actorName: 'Charlie');
      expect(notif.message, 'Charlie started following you');
    });

    test('returns default message for unknown type', () {
      final notif = _makeNotification(type: 'unknown', actorName: 'Dave');
      expect(notif.message, 'Dave interacted with you');
    });

    test('returns Someone when actor is null', () {
      final notif = AppNotification(
        id: 'n1',
        userId: 'u1',
        actorId: 'u2',
        actor: null,
        type: 'like',
        targetType: 'answer',
        targetId: 'a1',
        isRead: false,
        createdAt: DateTime.now(),
      );
      expect(notif.message, 'Someone liked your answer');
    });
  });

  group('AppNotification.timeAgo', () {
    test('returns now for recent', () {
      final notif = _makeNotificationWithTime(DateTime.now());
      expect(notif.timeAgo, 'now');
    });

    test('returns minutes ago', () {
      final notif = _makeNotificationWithTime(
        DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(notif.timeAgo, '5m ago');
    });

    test('returns hours ago', () {
      final notif = _makeNotificationWithTime(
        DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(notif.timeAgo, '3h ago');
    });

    test('returns days ago', () {
      final notif = _makeNotificationWithTime(
        DateTime.now().subtract(const Duration(days: 7)),
      );
      expect(notif.timeAgo, '7d ago');
    });
  });
}

AppNotification _makeNotification({
  required String type,
  required String actorName,
}) {
  return AppNotification.fromJson({
    'id': 'n1',
    'user_id': 'u1',
    'actor_id': 'u2',
    'actor': {
      'id': 'u2',
      'name': actorName,
      'created_at': '2024-01-01T00:00:00.000Z',
      'updated_at': '2024-01-01T00:00:00.000Z',
    },
    'type': type,
    'target_type': 'answer',
    'target_id': 'a1',
    'is_read': false,
    'created_at': '2024-01-01T00:00:00.000Z',
  });
}

AppNotification _makeNotificationWithTime(DateTime createdAt) {
  return AppNotification(
    id: 'n1',
    userId: 'u1',
    actorId: 'u2',
    type: 'like',
    targetType: 'answer',
    targetId: 'a1',
    isRead: false,
    createdAt: createdAt,
  );
}
