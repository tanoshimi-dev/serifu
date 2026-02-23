import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serifu/models/answer.dart';
import 'package:serifu/screens/answer_detail_screen.dart';
import 'package:serifu/screens/comment_screen.dart';

import '../helpers/mock_api.dart';
import '../helpers/test_data.dart';
import '../helpers/test_app.dart';

void main() {
  tearDown(() => tearDownTestApiClient());

  group('Scenario 3: Like & Comment', () {
    testWidgets('Like answer - optimistic UI updates count and icon',
        (tester) async {
      final mockClient = createMockClient(handlers: {
        'POST /api/v1/answers/:id/like': (_) => successResponse(),
      });

      setupTestApiClient(mockClient);

      final answer = Answer.fromJson(testAnswerJson(
        likeCount: 3,
        isLiked: false,
        user: testUserJson(id: testOtherUserId, name: 'Author'),
      ));

      await tester.pumpWidget(testApp(AnswerDetailScreen(answerId: answer.id, answer: answer)));
      await tester.pumpAndSettle();

      // Verify initial state: count = 3, unfilled heart
      expect(find.text('3'), findsWidgets);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      // Tap like
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();

      // Verify: count = 4, filled heart
      expect(find.text('4'), findsWidgets);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('Unlike answer - count decreases, icon changes',
        (tester) async {
      final mockClient = createMockClient(handlers: {
        'DELETE /api/v1/answers/:id/like': (_) => successResponse(),
      });

      setupTestApiClient(mockClient);

      final answer = Answer.fromJson(testAnswerJson(
        likeCount: 5,
        isLiked: true,
        user: testUserJson(id: testOtherUserId, name: 'Author'),
      ));

      await tester.pumpWidget(testApp(AnswerDetailScreen(answerId: answer.id, answer: answer)));
      await tester.pumpAndSettle();

      // Verify initial state: count = 5, filled heart
      expect(find.text('5'), findsWidgets);
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // Tap to unlike
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pumpAndSettle();

      // Verify: count = 4, outline heart
      expect(find.text('4'), findsWidgets);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('Navigate to comments and post a comment', (tester) async {
      final mockClient = createMockClient(handlers: {
        'GET /api/v1/answers/:id/comments': (_) => jsonListResponse([
              testCommentJson(
                user: testUserJson(id: testOtherUserId, name: 'Commenter'),
                content: 'Existing comment',
              ),
            ]),
        'POST /api/v1/answers/:id/comments': (request) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return jsonResponse(testCommentJson(
            id: 'comment-new',
            userId: testUserId,
            user: testUserJson(),
            content: body['content'] as String,
          ));
        },
      });

      setupTestApiClient(mockClient);

      final answer = Answer.fromJson(testAnswerJson(
        commentCount: 1,
        user: testUserJson(id: testOtherUserId, name: 'Author'),
      ));

      await tester.pumpWidget(testApp(CommentScreen(answerId: answer.id, answer: answer)));
      await tester.pumpAndSettle();

      // Verify existing comment is shown
      expect(find.text('Existing comment'), findsOneWidget);

      // Enter new comment
      await tester.enterText(
        find.byType(TextField),
        'My new comment',
      );
      await tester.pumpAndSettle();

      // Tap send
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Verify new comment appears in list
      expect(find.text('My new comment'), findsOneWidget);
    });

    testWidgets('Empty comments state shows message', (tester) async {
      final mockClient = createMockClient(handlers: {
        'GET /api/v1/answers/:id/comments': (_) => jsonListResponse([]),
      });

      setupTestApiClient(mockClient);

      final answer = Answer.fromJson(testAnswerJson(
        commentCount: 0,
        user: testUserJson(id: testOtherUserId, name: 'Author'),
      ));

      await tester.pumpWidget(testApp(CommentScreen(answerId: answer.id, answer: answer)));
      await tester.pumpAndSettle();

      expect(find.text('コメントはまだありません'), findsOneWidget);
    });
  });
}
