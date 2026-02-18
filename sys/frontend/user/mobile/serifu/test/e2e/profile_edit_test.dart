import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serifu/screens/profile_screen.dart';
import 'package:serifu/screens/login_screen.dart';

import '../helpers/mock_api.dart';
import '../helpers/test_data.dart';
import '../helpers/test_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => tearDownTestApiClient());

  group('Scenario 4: Profile Display & Edit', () {
    testWidgets('Display user info and stats', (tester) async {
      final mockClient = createMockClient(handlers: {
        'GET /api/v1/auth/me': (_) => jsonResponse(testUserJson(
              name: 'Alice',
              email: 'alice@example.com',
              bio: 'Hello world',
              followerCount: 100,
              followingCount: 50,
              answerCount: 25,
            )),
        'GET /api/v1/users/:id/answers': (_) => jsonListResponse([]),
      });

      setupTestApiClient(mockClient);

      await tester.pumpWidget(testApp(const ProfileScreen()));
      await tester.pumpAndSettle();

      // Verify user info
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('alice@example.com'), findsOneWidget);
      expect(find.text('Hello world'), findsOneWidget);

      // Verify stats
      expect(find.text('100'), findsOneWidget); // followers
      expect(find.text('50'), findsOneWidget); // following
      expect(find.text('25'), findsOneWidget); // answers
    });

    testWidgets('Edit mode, change name and bio, save', (tester) async {
      final mockClient = createMockClient(handlers: {
        'GET /api/v1/auth/me': (_) => jsonResponse(testUserJson(
              name: 'Alice',
              email: 'alice@example.com',
              bio: 'Old bio',
            )),
        'GET /api/v1/users/:id/answers': (_) => jsonListResponse([]),
        'PUT /api/v1/users/:id': (request) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return jsonResponse(testUserJson(
            name: body['name'] as String? ?? 'Alice',
            email: 'alice@example.com',
            bio: body['bio'] as String? ?? 'Old bio',
          ));
        },
      });

      setupTestApiClient(mockClient);

      await tester.pumpWidget(testApp(const ProfileScreen()));
      await tester.pumpAndSettle();

      // Tap edit icon in header (first Icons.edit, the one in the header)
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      // Verify edit form is shown
      expect(find.text('Edit Profile'), findsOneWidget);

      // Change name
      final nameField = find.widgetWithText(TextField, 'Name');
      await tester.enterText(nameField, 'Bob');

      // Change bio
      final bioField = find.widgetWithText(TextField, 'Bio');
      await tester.enterText(bioField, 'New bio');

      // Tap check icon to save
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      // Edit form should be gone
      expect(find.text('Edit Profile'), findsNothing);
      // Updated name/bio should be shown
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('New bio'), findsOneWidget);
    });

    testWidgets('Cancel edit restores original values', (tester) async {
      final mockClient = createMockClient(handlers: {
        'GET /api/v1/auth/me': (_) => jsonResponse(testUserJson(
              name: 'Alice',
              email: 'alice@example.com',
              bio: 'Original bio',
            )),
        'GET /api/v1/users/:id/answers': (_) => jsonListResponse([]),
      });

      setupTestApiClient(mockClient);

      await tester.pumpWidget(testApp(const ProfileScreen()));
      await tester.pumpAndSettle();

      // Tap edit icon in header
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      // Change name
      final nameField = find.widgetWithText(TextField, 'Name');
      await tester.enterText(nameField, 'ChangedName');

      // Scroll down to make Cancel button visible, then tap it
      final cancelButton = find.text('Cancel');
      await tester.ensureVisible(cancelButton);
      await tester.pumpAndSettle();
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Original name should be displayed
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('Logout navigates to LoginScreen', (tester) async {
      final mockClient = createMockClient(handlers: {
        'GET /api/v1/auth/me': (_) => jsonResponse(testUserJson(
              name: 'Alice',
              email: 'alice@example.com',
            )),
        'GET /api/v1/users/:id/answers': (_) => jsonListResponse([]),
      });

      setupTestApiClient(mockClient);

      await tester.pumpWidget(testApp(const ProfileScreen()));
      await tester.pumpAndSettle();

      // Tap logout icon
      await tester.tap(find.byIcon(Icons.logout));
      // Use pump with duration since LoginScreen has Image.asset that may not settle
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Should navigate to LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
