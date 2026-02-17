import 'package:flutter_test/flutter_test.dart';
import 'package:serifu/models/quiz.dart';

void main() {
  group('Quiz.fromJson', () {
    test('parses full fields with nested Category', () {
      final json = {
        'id': 'quiz-1',
        'title': 'Test Quiz',
        'description': 'A description',
        'requirement': '150 chars',
        'category_id': 'cat-1',
        'category': {
          'id': 'cat-1',
          'name': 'Fun',
          'description': 'Fun category',
          'icon': '🎉',
          'color': '#FF0000',
          'sort_order': 1,
          'status': 'active',
        },
        'release_date': '2024-06-01T00:00:00.000Z',
        'status': 'active',
        'answer_count': 5,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-02T00:00:00.000Z',
      };

      final quiz = Quiz.fromJson(json);

      expect(quiz.id, 'quiz-1');
      expect(quiz.title, 'Test Quiz');
      expect(quiz.description, 'A description');
      expect(quiz.requirement, '150 chars');
      expect(quiz.categoryId, 'cat-1');
      expect(quiz.category, isNotNull);
      expect(quiz.category!.name, 'Fun');
      expect(quiz.status, 'active');
      expect(quiz.answerCount, 5);
    });

    test('parses without category (null)', () {
      final json = {
        'id': 'quiz-2',
        'title': 'No Category',
        'release_date': '2024-06-01T00:00:00.000Z',
        'status': 'draft',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final quiz = Quiz.fromJson(json);

      expect(quiz.category, isNull);
      expect(quiz.categoryId, isNull);
      expect(quiz.description, '');
      expect(quiz.requirement, '');
      expect(quiz.answerCount, 0);
    });
  });

  group('Quiz.toJson', () {
    test('serializes correct fields', () {
      final quiz = Quiz(
        id: 'q1',
        title: 'My Quiz',
        description: 'Desc',
        requirement: 'Req',
        categoryId: 'c1',
        releaseDate: DateTime.utc(2024, 6, 1),
        status: 'active',
        answerCount: 10,
        createdAt: DateTime.utc(2024),
        updatedAt: DateTime.utc(2024),
      );

      final json = quiz.toJson();

      expect(json['id'], 'q1');
      expect(json['title'], 'My Quiz');
      expect(json['description'], 'Desc');
      expect(json['requirement'], 'Req');
      expect(json['category_id'], 'c1');
      expect(json['status'], 'active');
      expect(json['release_date'], contains('2024-06-01'));
      expect(json.containsKey('answer_count'), false);
      expect(json.containsKey('created_at'), false);
    });
  });

  group('Category.fromJson', () {
    test('parses full fields', () {
      final json = {
        'id': 'cat-1',
        'name': 'Science',
        'description': 'Science topics',
        'icon': '🔬',
        'color': '#00FF00',
        'sort_order': 2,
        'status': 'active',
      };

      final cat = Category.fromJson(json);

      expect(cat.id, 'cat-1');
      expect(cat.name, 'Science');
      expect(cat.sortOrder, 2);
      expect(cat.status, 'active');
    });

    test('uses defaults for optional fields', () {
      final json = {
        'id': 'cat-2',
        'name': 'Minimal',
      };

      final cat = Category.fromJson(json);

      expect(cat.sortOrder, 0);
      expect(cat.status, 'active');
      expect(cat.description, isNull);
      expect(cat.icon, isNull);
      expect(cat.color, isNull);
    });
  });
}
