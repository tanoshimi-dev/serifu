import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:serifu/api/api_client.dart';
import 'package:serifu/models/answer.dart';
import 'package:serifu/models/quiz.dart';
import 'package:serifu/repositories/auth_repository.dart';
import 'package:serifu/repositories/quiz_repository.dart';
import 'package:serifu/repositories/answer_repository.dart';
import 'package:serifu/repositories/notification_repository.dart';
import 'package:serifu/repositories/user_repository.dart';
import 'package:serifu/screens/answer_detail_screen.dart';
import 'package:serifu/screens/feed_screen.dart';
import 'package:serifu/screens/home_screen.dart';
import 'package:serifu/screens/login_screen.dart';
import 'package:serifu/screens/profile_screen.dart';
import 'package:serifu/screens/quiz_detail_screen.dart';
import 'package:serifu/screens/register_screen.dart';
import 'package:serifu/screens/user_profile_screen.dart';
import 'package:serifu/theme/app_theme.dart';

import 'test_data.dart';

const testBaseUrl = 'http://localhost:8080/api/v1';

/// Creates a test [ApiClient] with the given mock [http.Client],
/// overrides all global singletons, and sets up auth state.
void setupTestApiClient(http.Client mockClient, {
  String userId = testUserId,
  String token = testToken,
}) {
  final client = ApiClient(httpClient: mockClient, baseUrl: testBaseUrl);
  client.setUserId(userId);
  client.setToken(token);

  apiClient = client;
  authRepository = AuthRepository(client: client);
  quizRepository = QuizRepository(client: client);
  answerRepository = AnswerRepository(client: client);
  notificationRepository = NotificationRepository(client: client);
  userRepository = UserRepository(client: client);
}

/// Restores all global singletons to their default instances.
void tearDownTestApiClient() {
  apiClient = ApiClient();
  authRepository = AuthRepository();
  quizRepository = QuizRepository();
  answerRepository = AnswerRepository();
  notificationRepository = NotificationRepository();
  userRepository = UserRepository();
}

/// Wraps [home] in a [MaterialApp.router] with GoRouter for widget testing.
/// Provides routes for all navigation targets used in E2E tests.
Widget testApp(Widget home) {
  final router = GoRouter(
    initialLocation: '/__test__',
    routes: [
      GoRoute(
        path: '/__test__',
        builder: (context, state) => Scaffold(body: home),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: HomeScreen()),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/feed',
        builder: (context, state) {
          final quiz = state.extra as Quiz?;
          return Scaffold(body: FeedScreen(quiz: quiz));
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) =>
            const Scaffold(body: ProfileScreen()),
      ),
      GoRoute(
        path: '/quiz/:id',
        builder: (context, state) {
          final quiz = state.extra as Quiz?;
          return QuizDetailScreen(
            quizId: state.pathParameters['id']!,
            quiz: quiz,
          );
        },
      ),
      GoRoute(
        path: '/answer/:id',
        builder: (context, state) {
          final answer = state.extra as Answer?;
          return AnswerDetailScreen(
            answerId: state.pathParameters['id']!,
            answer: answer,
          );
        },
      ),
      GoRoute(
        path: '/user/:id',
        builder: (context, state) => UserProfileScreen(
          userId: state.pathParameters['id']!,
        ),
      ),
    ],
  );

  return MaterialApp.router(
    theme: AppTheme.theme,
    routerConfig: router,
  );
}
