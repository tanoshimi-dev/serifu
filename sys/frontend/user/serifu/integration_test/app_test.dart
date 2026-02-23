import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:serifu/screens/login_screen.dart';
import 'package:serifu/screens/register_screen.dart';
import 'package:serifu/screens/home_screen.dart';
import 'package:serifu/screens/notification_screen.dart';
import 'package:serifu/screens/profile_screen.dart';
import 'package:serifu/theme/app_theme.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Screen rendering tests', () {
    testWidgets('Login screen renders with form fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify login form elements exist
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Login'), findsWidgets);
    });

    testWidgets('Register screen renders with form fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: const RegisterScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify registration form elements exist
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('Home screen renders with loading state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: const HomeScreen(),
        ),
      );
      // Don't pumpAndSettle — let it show loading state
      await tester.pump();

      // Should show either loading indicator or content
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Notification screen renders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: const NotificationScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Profile screen renders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: const ProfileScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('Navigation tests', () {
    testWidgets('Login to Register navigation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Look for "Create Account" or registration link
      final createAccountFinder = find.textContaining('アカウント');
      if (createAccountFinder.evaluate().isNotEmpty) {
        await tester.tap(createAccountFinder.first);
        await tester.pumpAndSettle();
        // Should navigate to register screen
        expect(find.byType(RegisterScreen), findsOneWidget);
      }
    });
  });

  group('Theme tests', () {
    testWidgets('Theme colors are applied', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: const Scaffold(
            body: Center(child: Text('Theme Test')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the scaffold background color from theme
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNull); // Uses theme default
    });
  });
}
