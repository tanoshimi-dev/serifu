import 'package:flutter_test/flutter_test.dart';
import 'package:serifu/screens/notification_screen.dart';
import 'package:serifu/screens/answer_detail_screen.dart';

import '../helpers/mock_api.dart';
import '../helpers/test_data.dart';
import '../helpers/test_app.dart';

void main() {
  tearDown(() => tearDownTestApiClient());

  group('Scenario 5: Notifications', () {
    testWidgets('Display notifications (like, comment, follow)',
        (tester) async {
      final mockClient = createMockClient(handlers: {
        'GET /api/v1/notifications': (_) => jsonListResponse([
              testNotificationJson(
                id: 'n1',
                type: 'like',
                targetType: 'answer',
                targetId: testAnswerId,
                actor: testUserJson(id: 'actor-1', name: 'Liker'),
              ),
              testNotificationJson(
                id: 'n2',
                type: 'comment',
                targetType: 'answer',
                targetId: testAnswerId,
                actor: testUserJson(id: 'actor-2', name: 'Commenter'),
              ),
              testNotificationJson(
                id: 'n3',
                type: 'follow',
                targetType: 'user',
                targetId: testUserId,
                actor: testUserJson(id: 'actor-3', name: 'Follower'),
              ),
            ]),
        'PUT /api/v1/notifications/read-all': (_) => successResponse(),
      });

      setupTestApiClient(mockClient);

      await tester.pumpWidget(testApp(const NotificationScreen()));
      await tester.pumpAndSettle();

      // Verify notification messages
      expect(find.text('Liker liked your answer'), findsOneWidget);
      expect(find.text('Commenter commented on your answer'), findsOneWidget);
      expect(find.text('Follower started following you'), findsOneWidget);
    });

    testWidgets('Tap like notification navigates to AnswerDetailScreen',
        (tester) async {
      final mockClient = createMockClient(handlers: {
        'GET /api/v1/notifications': (_) => jsonListResponse([
              testNotificationJson(
                type: 'like',
                targetType: 'answer',
                targetId: testAnswerId,
                actor: testUserJson(id: 'actor-1', name: 'Liker'),
              ),
            ]),
        'PUT /api/v1/notifications/read-all': (_) => successResponse(),
        'GET /api/v1/answers/:id': (_) => jsonResponse(testAnswerJson(
              user: testUserJson(id: testOtherUserId, name: 'Author'),
            )),
      });

      setupTestApiClient(mockClient);

      await tester.pumpWidget(testApp(const NotificationScreen()));
      await tester.pumpAndSettle();

      // Tap the notification
      await tester.tap(find.text('Liker liked your answer'));
      await tester.pumpAndSettle();

      // Verify AnswerDetailScreen
      expect(find.byType(AnswerDetailScreen), findsOneWidget);
      expect(find.text('回答詳細'), findsOneWidget);
    });

    testWidgets('Empty notifications shows empty state', (tester) async {
      final mockClient = createMockClient(handlers: {
        'GET /api/v1/notifications': (_) => jsonListResponse([]),
        'PUT /api/v1/notifications/read-all': (_) => successResponse(),
      });

      setupTestApiClient(mockClient);

      await tester.pumpWidget(testApp(const NotificationScreen()));
      await tester.pumpAndSettle();

      expect(find.text('No notifications yet'), findsOneWidget);
    });
  });
}
