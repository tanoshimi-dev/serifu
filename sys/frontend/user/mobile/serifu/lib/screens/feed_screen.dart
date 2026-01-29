import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../models/answer.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_card.dart';
import '../widgets/bottom_nav_bar.dart';

class FeedScreen extends StatefulWidget {
  final Quiz quiz;

  const FeedScreen({
    super.key,
    required this.quiz,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int _selectedSortIndex = 0;
  final List<String> _sortTabs = ['🔥 Popular', '🆕 Latest', '⭐ Top', '👥 Following'];

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
            currentIndex: 1,
            onTap: (index) {
              if (index == 0) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
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
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.quiz.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
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
          _buildSortTabs(),
          const SizedBox(height: 16),
          ...sampleAnswers.map((answer) => AnswerCard(answer: answer)),
        ],
      ),
    );
  }

  Widget _buildSortTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _sortTabs.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          final isActive = index == _selectedSortIndex;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedSortIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primaryStart : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? AppTheme.primaryStart : const Color(0xFFE0E0E0),
                    width: 2,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : AppTheme.textGray,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
