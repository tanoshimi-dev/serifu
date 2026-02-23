import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serifu/screens/login_screen.dart';
import 'package:serifu/screens/home_screen.dart';
import 'package:serifu/screens/register_screen.dart';

import '../helpers/mock_api.dart';
import '../helpers/test_data.dart';
import '../helpers/test_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => tearDownTestApiClient());

  group('Scenario 1: Login -> Home', () {
    testWidgets('Login success navigates to HomeScreen', (tester) async {
      final mockClient = createMockClient(handlers: {
        'POST /api/v1/auth/login': (_) => jsonResponse({
              'token': testToken,
              'user': testUserJson(),
            }),
        'GET /api/v1/quizzes/daily': (_) =>
            jsonListResponse([testQuizJson()]),
        'GET /api/v1/trending/answers': (_) =>
            jsonListResponse([testAnswerJson(user: testUserJson())]),
        'GET /api/v1/categories': (_) =>
            jsonListResponse([testCategoryJson()]),
        'GET /api/v1/rankings/daily': (_) =>
            jsonListResponse([testAnswerJson(user: testUserJson())]),
        'GET /api/v1/auth/me': (_) => jsonResponse(testUserJson()),
        'GET /api/v1/notifications/unread-count': (_) =>
            jsonResponse({'unread_count': 2}),
      });

      // Don't set userId/token yet — simulates pre-login state
      setupTestApiClient(mockClient, userId: '', token: '');

      await tester.pumpWidget(testApp(const LoginScreen()));
      await tester.pumpAndSettle();

      // Enter email and password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      // Tap Sign In
      await tester.tap(find.text('Sign In'));
      // Pump enough frames for async login + navigation + HomeScreen load
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      // Verify HomeScreen loaded
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text("Today's Quiz"), findsOneWidget);
    });

    testWidgets('Login failure shows error message', (tester) async {
      final mockClient = createMockClient(handlers: {
        'POST /api/v1/auth/login': (_) =>
            errorResponse('Invalid credentials', statusCode: 401),
      });

      setupTestApiClient(mockClient, userId: '', token: '');

      await tester.pumpWidget(testApp(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'bad@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'wrongpass',
      );

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Should still be on LoginScreen with error message
      expect(find.byType(LoginScreen), findsOneWidget);
      // Error includes status code suffix
      expect(find.textContaining('Invalid credentials'), findsOneWidget);
    });

    testWidgets('Login -> Register -> Login navigation', (tester) async {
      final mockClient = createMockClient(handlers: {});
      setupTestApiClient(mockClient, userId: '', token: '');

      await tester.pumpWidget(testApp(const LoginScreen()));
      await tester.pumpAndSettle();

      // Scroll down to find "Create Account" (may be off-screen)
      final createAccount = find.text('Create Account');
      await tester.ensureVisible(createAccount);
      await tester.pumpAndSettle();
      await tester.tap(createAccount);
      await tester.pumpAndSettle();

      // Verify RegisterScreen
      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text('Join the community'), findsOneWidget);

      // Scroll down to find "Sign In" link
      final signIn = find.text('Sign In').last;
      await tester.ensureVisible(signIn);
      await tester.pumpAndSettle();
      await tester.tap(signIn);
      await tester.pumpAndSettle();

      // Verify back on LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
    });
  });
}
