import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:serifu/api/api_client.dart';
import 'package:serifu/repositories/auth_repository.dart';
import 'package:serifu/repositories/quiz_repository.dart';
import 'package:serifu/repositories/answer_repository.dart';
import 'package:serifu/repositories/notification_repository.dart';
import 'package:serifu/repositories/user_repository.dart';
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

/// Wraps [home] in a [MaterialApp] with the app theme for widget testing.
Widget testApp(Widget home) {
  return MaterialApp(
    theme: AppTheme.theme,
    home: home,
  );
}
