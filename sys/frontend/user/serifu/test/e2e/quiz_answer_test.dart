import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serifu/screens/write_screen.dart';
import 'package:serifu/screens/quiz_detail_screen.dart';
import 'package:serifu/screens/feed_screen.dart';
import 'package:serifu/models/quiz.dart';

import '../helpers/mock_api.dart';
import '../helpers/test_data.dart';
import '../helpers/test_app.dart';

void main() {
  tearDown(() => tearDownTestApiClient());

  group('Scenario 2: Quiz -> Detail -> Post Answer', () {
    testWidgets('WriteScreen shows quizzes, navigate to detail, submit answer',
        (tester) async {
      final mockClient = createMockClient(handlers: {
        'GET /api/v1/quizzes': (_) => jsonListResponse([
              testQuizJson(),
              testQuizJson(id: 'quiz-002', title: 'Second Quiz'),
            ]),
        'GET /api/v1/categories': (_) =>
            jsonListResponse([testCategoryJson()]),
        'POST /api/v1/quizzes/:id/answers': (_) =>
            jsonResponse(testAnswerJson(content: 'My great answer')),
        'GET /api/v1/quizzes/:id/answers': (_) => jsonListResponse([
              testAnswerJson(user: testUserJson()),
            ]),
        'GET /api/v1/trending/answers': (_) => jsonListResponse([]),
      });

      setupTestApiClient(mockClient);

      await tester.pumpWidget(testApp(const WriteScreen()));
      await tester.pumpAndSettle();

      // Verify quiz list items are shown
      expect(find.textContaining('Test Quiz Title'), findsOneWidget);
      expect(find.textContaining('Second Quiz'), findsOneWidget);

      // Tap first quiz to navigate to detail
      await tester.tap(find.textContaining('Test Quiz Title'));
      await tester.pumpAndSettle();

      // Verify QuizDetailScreen
      expect(find.byType(QuizDetailScreen), findsOneWidget);
      expect(find.text('Submit Answer'), findsOneWidget);

      // Enter answer text
      await tester.enterText(
        find.byType(TextField),
        'My great answer',
      );
      await tester.pumpAndSettle();

      // Tap Submit Answer
      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();

      // Verify success SnackBar
      expect(find.text('Answer submitted successfully!'), findsOneWidget);
    });

    testWidgets('Empty answer shows validation SnackBar', (tester) async {
      final quiz = Quiz.fromJson(testQuizJson());
      final mockClient = createMockClient(handlers: {});

      setupTestApiClient(mockClient);

      await tester.pumpWidget(testApp(QuizDetailScreen(quizId: quiz.id, quiz: quiz)));
      await tester.pumpAndSettle();

      // Tap Submit without entering text
      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();

      // Verify validation message
      expect(find.text('Please enter your answer'), findsOneWidget);
    });

    testWidgets('See Other Answers navigates to FeedScreen', (tester) async {
      final quiz = Quiz.fromJson(testQuizJson());
      final mockClient = createMockClient(handlers: {
        'GET /api/v1/quizzes/:id/answers': (_) => jsonListResponse([
              testAnswerJson(user: testUserJson()),
            ]),
        'GET /api/v1/categories': (_) =>
            jsonListResponse([testCategoryJson()]),
      });

      setupTestApiClient(mockClient);

      await tester.pumpWidget(testApp(QuizDetailScreen(quizId: quiz.id, quiz: quiz)));
      await tester.pumpAndSettle();

      // Scroll down in the ListView to reveal "See Other Answers" button
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      final seeOtherAnswers = find.text('See Other Answers');
      await tester.tap(seeOtherAnswers);
      await tester.pumpAndSettle();

      // Verify FeedScreen appeared
      expect(find.byType(FeedScreen), findsOneWidget);
    });
  });
}
