import 'package:flutter_test/flutter_test.dart';
import 'package:serifu/models/answer.dart';

void main() {
  group('Answer.fromJson', () {
    test('parses full fields with nested User', () {
      final json = {
        'id': 'a1',
        'quiz_id': 'q1',
        'user_id': 'u1',
        'user': {
          'id': 'u1',
          'name': 'TestUser',
          'created_at': '2024-01-01T00:00:00.000Z',
          'updated_at': '2024-01-01T00:00:00.000Z',
        },
        'content': 'My answer text',
        'like_count': 10,
        'comment_count': 3,
        'view_count': 100,
        'status': 'active',
        'created_at': '2024-06-01T00:00:00.000Z',
        'updated_at': '2024-06-02T00:00:00.000Z',
        'is_liked': true,
      };

      final answer = Answer.fromJson(json);

      expect(answer.id, 'a1');
      expect(answer.quizId, 'q1');
      expect(answer.userId, 'u1');
      expect(answer.user, isNotNull);
      expect(answer.user!.name, 'TestUser');
      expect(answer.content, 'My answer text');
      expect(answer.likeCount, 10);
      expect(answer.commentCount, 3);
      expect(answer.viewCount, 100);
      expect(answer.status, 'active');
      expect(answer.isLiked, true);
    });

    test('parses with null user and default counts', () {
      final json = {
        'id': 'a2',
        'quiz_id': 'q2',
        'user_id': 'u2',
        'content': 'Minimal answer',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final answer = Answer.fromJson(json);

      expect(answer.user, isNull);
      expect(answer.likeCount, 0);
      expect(answer.commentCount, 0);
      expect(answer.viewCount, 0);
      expect(answer.status, 'active');
      expect(answer.isLiked, isNull);
    });
  });

  group('Answer.toJson', () {
    test('outputs only quiz_id and content', () {
      final answer = Answer(
        id: 'a1',
        quizId: 'q1',
        userId: 'u1',
        content: 'Test content',
        likeCount: 5,
        commentCount: 2,
        viewCount: 50,
        status: 'active',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      final json = answer.toJson();

      expect(json['quiz_id'], 'q1');
      expect(json['content'], 'Test content');
      expect(json.length, 2);
    });
  });

  group('Answer.copyWith', () {
    test('updates likeCount, commentCount, isLiked', () {
      final answer = Answer(
        id: 'a1',
        quizId: 'q1',
        userId: 'u1',
        content: 'Test',
        likeCount: 0,
        commentCount: 0,
        viewCount: 0,
        status: 'active',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        isLiked: false,
      );

      final updated = answer.copyWith(
        likeCount: 5,
        commentCount: 3,
        isLiked: true,
      );

      expect(updated.likeCount, 5);
      expect(updated.commentCount, 3);
      expect(updated.isLiked, true);
      expect(updated.content, 'Test');
      expect(updated.viewCount, 0);
    });

    test('retains unchanged fields', () {
      final answer = Answer(
        id: 'a1',
        quizId: 'q1',
        userId: 'u1',
        content: 'Original',
        likeCount: 10,
        commentCount: 5,
        viewCount: 100,
        status: 'active',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        isLiked: true,
      );

      final updated = answer.copyWith(likeCount: 11);

      expect(updated.likeCount, 11);
      expect(updated.commentCount, 5);
      expect(updated.isLiked, true);
      expect(updated.id, 'a1');
    });
  });

  group('Comment.fromJson', () {
    test('parses full fields', () {
      final json = {
        'id': 'c1',
        'answer_id': 'a1',
        'user_id': 'u1',
        'user': {
          'id': 'u1',
          'name': 'Commenter',
          'created_at': '2024-01-01T00:00:00.000Z',
          'updated_at': '2024-01-01T00:00:00.000Z',
        },
        'content': 'Nice answer!',
        'status': 'active',
        'created_at': '2024-06-01T00:00:00.000Z',
        'updated_at': '2024-06-01T00:00:00.000Z',
      };

      final comment = Comment.fromJson(json);

      expect(comment.id, 'c1');
      expect(comment.answerId, 'a1');
      expect(comment.userId, 'u1');
      expect(comment.user, isNotNull);
      expect(comment.user!.name, 'Commenter');
      expect(comment.content, 'Nice answer!');
      expect(comment.status, 'active');
    });

    test('parses with null user and default status', () {
      final json = {
        'id': 'c2',
        'answer_id': 'a2',
        'user_id': 'u2',
        'content': 'Minimal comment',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final comment = Comment.fromJson(json);

      expect(comment.user, isNull);
      expect(comment.status, 'active');
    });
  });
}
