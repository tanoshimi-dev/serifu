import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../theme/app_theme.dart';
import '../widgets/quiz_card.dart';
import '../widgets/bottom_nav_bar.dart';
import 'quiz_detail_screen.dart';
import 'feed_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  void _onNavTap(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FeedScreen(quiz: sampleQuizzes.first),
        ),
      );
    } else {
      setState(() {
        _currentNavIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildContent(),
          ),
          BottomNavBar(
            currentIndex: _currentNavIndex,
            onTap: _onNavTap,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.menu, color: Colors.white, size: 24),
              const Text(
                'Quiz + SNS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: const [
                  Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                  SizedBox(width: 15),
                  Icon(Icons.person_outline, color: Colors.white, size: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      color: AppTheme.background,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildDateBadge(),
          const SizedBox(height: 20),
          ...sampleQuizzes.map((quiz) => QuizCard(
                quiz: quiz,
                onTap: () => _navigateToQuizDetail(quiz),
              )),
        ],
      ),
    );
  }

  Widget _buildDateBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        "📅 Today's Quiz - January 30",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryStart,
        ),
      ),
    );
  }

  void _navigateToQuizDetail(Quiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizDetailScreen(quiz: quiz),
      ),
    );
  }
}
