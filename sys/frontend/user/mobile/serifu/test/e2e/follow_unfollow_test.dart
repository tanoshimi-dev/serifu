import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serifu/screens/user_profile_screen.dart';
import 'package:serifu/screens/profile_screen.dart';

import '../helpers/mock_api.dart';
import '../helpers/test_data.dart';
import '../helpers/test_app.dart';

void main() {
  tearDown(() => tearDownTestApiClient());

  group('Scenario 6: Follow / Unfollow', () {
    testWidgets('Follow user - button text changes, count increases',
        (tester) async {
      final mockClient = createMockClient(handlers: {
        'GET /api/v1/users/:id': (_) => jsonResponse(testUserJson(
              id: testOtherUserId,
              name: 'OtherUser',
              bio: 'I am someone else',
              followerCount: 10,
              followingCount: 5,
              answerCount: 3,
              isFollowing: false,
            )),
        'GET /api/v1/users/:id/answers': (_) => jsonListResponse([]),
        'POST /api/v1/users/:id/follow': (_) => successResponse(),
      });

      setupTestApiClient(mockClient);

      await tester
          .pumpWidget(testApp(UserProfileScreen(userId: testOtherUserId)));
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('フォローする'), findsOneWidget);
      expect(find.text('10'), findsOneWidget); // follower count

      // Tap follow
      await tester.tap(find.text('フォローする'));
      await tester.pumpAndSettle();

      // Verify updated state
      expect(find.text('フォロー中'), findsWidgets);
      expect(find.text('11'), findsOneWidget); // follower count +1
    });

    testWidgets('Unfollow user - button text changes, count decreases',
        (tester) async {
      final mockClient = createMockClient(handlers: {
        'GET /api/v1/users/:id': (_) => jsonResponse(testUserJson(
              id: testOtherUserId,
              name: 'OtherUser',
              followerCount: 10,
              followingCount: 5,
              answerCount: 3,
              isFollowing: true,
            )),
        'GET /api/v1/users/:id/answers': (_) => jsonListResponse([]),
        'DELETE /api/v1/users/:id/follow': (_) => successResponse(),
      });

      setupTestApiClient(mockClient);

      await tester
          .pumpWidget(testApp(UserProfileScreen(userId: testOtherUserId)));
      await tester.pumpAndSettle();

      // Verify initial state: already following
      expect(find.text('フォロー中'), findsWidgets);
      expect(find.text('10'), findsOneWidget); // follower count

      // Tap to unfollow - find the follow button specifically
      final followButton = find.widgetWithText(Container, 'フォロー中');
      await tester.tap(followButton.first);
      await tester.pumpAndSettle();

      // Verify: unfollowed
      expect(find.text('フォローする'), findsOneWidget);
      expect(find.text('9'), findsOneWidget); // follower count -1
    });

    testWidgets('Own profile redirects to ProfileScreen', (tester) async {
      final mockClient = createMockClient(handlers: {
        'GET /api/v1/auth/me': (_) => jsonResponse(testUserJson()),
        'GET /api/v1/users/:id/answers': (_) => jsonListResponse([]),
      });

      // Set userId to the same as the profile being viewed
      setupTestApiClient(mockClient, userId: testUserId);

      await tester
          .pumpWidget(testApp(UserProfileScreen(userId: testUserId)));
      await tester.pumpAndSettle();

      // Should redirect to ProfileScreen
      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });
}
