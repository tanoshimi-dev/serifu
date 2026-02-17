import 'package:flutter_test/flutter_test.dart';
import 'package:serifu/models/user.dart';

void main() {
  group('User.fromJson', () {
    test('parses full fields correctly', () {
      final json = {
        'id': 'user-123',
        'email': 'test@example.com',
        'name': 'TestUser',
        'avatar': 'https://example.com/avatar.jpg',
        'bio': 'Hello world',
        'total_likes': 42,
        'status': 'active',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-02T00:00:00.000Z',
        'follower_count': 10,
        'following_count': 5,
        'answer_count': 3,
        'is_following': true,
      };

      final user = User.fromJson(json);

      expect(user.id, 'user-123');
      expect(user.email, 'test@example.com');
      expect(user.name, 'TestUser');
      expect(user.avatar, 'https://example.com/avatar.jpg');
      expect(user.bio, 'Hello world');
      expect(user.totalLikes, 42);
      expect(user.status, 'active');
      expect(user.followerCount, 10);
      expect(user.followingCount, 5);
      expect(user.answerCount, 3);
      expect(user.isFollowing, true);
    });

    test('uses defaults for null optional fields', () {
      final json = {
        'id': 'user-456',
        'name': 'Minimal',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final user = User.fromJson(json);

      expect(user.email, '');
      expect(user.totalLikes, 0);
      expect(user.status, 'active');
      expect(user.avatar, isNull);
      expect(user.bio, isNull);
      expect(user.followerCount, isNull);
      expect(user.followingCount, isNull);
      expect(user.answerCount, isNull);
      expect(user.isFollowing, isNull);
    });
  });

  group('User.avatarInitial', () {
    test('returns uppercase first letter', () {
      final user = _makeUser(name: 'alice');
      expect(user.avatarInitial, 'A');
    });

    test('returns ? for empty name', () {
      final user = _makeUser(name: '');
      expect(user.avatarInitial, '?');
    });
  });

  group('User.displayName', () {
    test('returns @name format', () {
      final user = _makeUser(name: 'TestUser');
      expect(user.displayName, '@TestUser');
    });

    test('returns @unknown for empty name', () {
      final user = _makeUser(name: '');
      expect(user.displayName, '@unknown');
    });
  });

  group('User.copyWith', () {
    test('updates followerCount, followingCount, isFollowing', () {
      final user = _makeUser(name: 'Test');
      final updated = user.copyWith(
        followerCount: 100,
        followingCount: 50,
        isFollowing: true,
      );

      expect(updated.followerCount, 100);
      expect(updated.followingCount, 50);
      expect(updated.isFollowing, true);
      expect(updated.name, 'Test');
      expect(updated.id, user.id);
    });

    test('retains unchanged fields', () {
      final user = User.fromJson({
        'id': 'u1',
        'email': 'e@e.com',
        'name': 'Name',
        'total_likes': 5,
        'status': 'active',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
        'follower_count': 10,
        'following_count': 20,
        'is_following': false,
      });

      final updated = user.copyWith(followerCount: 11);

      expect(updated.followerCount, 11);
      expect(updated.followingCount, 20);
      expect(updated.isFollowing, false);
      expect(updated.email, 'e@e.com');
      expect(updated.totalLikes, 5);
    });
  });
}

User _makeUser({required String name}) {
  return User(
    id: 'test-id',
    email: 'test@test.com',
    name: name,
    totalLikes: 0,
    status: 'active',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}
