import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/answer.dart';
import '../models/quiz.dart';
import '../repositories/answer_repository.dart';
import '../repositories/quiz_repository.dart';
import '../screens/answer_detail_screen.dart';
import '../screens/category_quizzes_screen.dart';
import '../screens/comment_screen.dart';
import '../screens/feed_screen.dart';
import '../screens/follow_list_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/notification_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/quiz_detail_screen.dart';
import '../screens/rankings_screen.dart';
import '../screens/register_screen.dart';
import '../screens/user_profile_screen.dart';
import '../screens/write_screen.dart';
import '../services/auth_service.dart';
import '../widgets/app_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isLoggedIn = authService.isLoggedInSync;
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && isAuthRoute) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/feed',
          builder: (context, state) {
            final quiz = state.extra as Quiz?;
            return FeedScreen(quiz: quiz);
          },
        ),
        GoRoute(
          path: '/write',
          builder: (context, state) => const WriteScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/rankings',
          builder: (context, state) => const RankingsScreen(),
        ),
        GoRoute(
          path: '/quiz/:id',
          builder: (context, state) {
            final quiz = state.extra as Quiz?;
            final quizId = state.pathParameters['id']!;
            return QuizDetailScreen(quizId: quizId, quiz: quiz);
          },
        ),
        GoRoute(
          path: '/answer/:id',
          builder: (context, state) {
            final answer = state.extra as Answer?;
            final answerId = state.pathParameters['id']!;
            return AnswerDetailScreen(answerId: answerId, answer: answer);
          },
        ),
        GoRoute(
          path: '/answer/:id/comments',
          builder: (context, state) {
            final answer = state.extra as Answer?;
            final answerId = state.pathParameters['id']!;
            return CommentScreen(answerId: answerId, answer: answer);
          },
        ),
        GoRoute(
          path: '/user/:id',
          builder: (context, state) {
            final userId = state.pathParameters['id']!;
            return UserProfileScreen(userId: userId);
          },
        ),
        GoRoute(
          path: '/user/:id/followers',
          builder: (context, state) {
            final userId = state.pathParameters['id']!;
            return FollowListScreen(userId: userId, isFollowers: true);
          },
        ),
        GoRoute(
          path: '/user/:id/following',
          builder: (context, state) {
            final userId = state.pathParameters['id']!;
            return FollowListScreen(userId: userId, isFollowers: false);
          },
        ),
        GoRoute(
          path: '/category/:id',
          builder: (context, state) {
            final category = state.extra as Category?;
            final categoryId = state.pathParameters['id']!;
            return CategoryQuizzesScreen(
                categoryId: categoryId, category: category);
          },
        ),
      ],
    ),
  ],
);
