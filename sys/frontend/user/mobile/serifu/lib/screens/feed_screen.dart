import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../models/answer.dart';
import '../repositories/quiz_repository.dart';
import '../repositories/answer_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_card.dart';
import '../widgets/bottom_nav_bar.dart';
import 'answer_detail_screen.dart';
import 'comment_screen.dart';
import 'user_profile_screen.dart';
import 'write_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

class FeedScreen extends StatefulWidget {
  final Quiz? quiz;

  const FeedScreen({
    super.key,
    this.quiz,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int _selectedSortIndex = 0;
  final List<(String, AnswerSort)> _sortTabs = [
    ('🔥 Popular', AnswerSort.popular),
    ('🆕 Latest', AnswerSort.latest),
    ('⭐ Trending', AnswerSort.trending),
  ];

  List<Answer> _answers = [];
  List<Category> _categories = [];
  String? _selectedCategoryId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _fetchAnswers(),
        quizRepository.getCategories(),
      ]);
      setState(() {
        _answers = results[0] as List<Answer>;
        _categories = results[1] as List<Category>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<List<Answer>> _fetchAnswers() async {
    if (widget.quiz != null) {
      return answerRepository.getAnswersForQuiz(
        widget.quiz!.id,
        sort: _sortTabs[_selectedSortIndex].$2,
      );
    }

    if (_selectedCategoryId != null) {
      final quizzes = await quizRepository.getQuizzes(
        categoryId: _selectedCategoryId,
      );
      if (quizzes.isEmpty) return [];
      final answerLists = await Future.wait(
        quizzes.map((q) => answerRepository.getAnswersForQuiz(q.id)),
      );
      final allAnswers = answerLists.expand((list) => list).toList();
      allAnswers.sort((a, b) => b.likeCount.compareTo(a.likeCount));
      return allAnswers;
    }

    return answerRepository.getTrendingAnswers();
  }

  void _onCategoryChanged(String? categoryId) {
    if (categoryId == _selectedCategoryId) return;
    setState(() => _selectedCategoryId = categoryId);
    _loadAnswers();
  }

  Future<void> _loadAnswers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final answers = await _fetchAnswers();
      setState(() {
        _answers = answers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSortChanged(int index) {
    if (index != _selectedSortIndex) {
      setState(() => _selectedSortIndex = index);
      _loadAnswers();
    }
  }

  Future<void> _toggleLike(Answer answer) async {
    final isLiked = answer.isLiked ?? false;
    final newLikeCount = isLiked ? answer.likeCount - 1 : answer.likeCount + 1;

    setState(() {
      final index = _answers.indexWhere((a) => a.id == answer.id);
      if (index != -1) {
        _answers[index] = answer.copyWith(
          likeCount: newLikeCount,
          isLiked: !isLiked,
        );
      }
    });

    try {
      if (isLiked) {
        await answerRepository.unlikeAnswer(answer.id);
      } else {
        await answerRepository.likeAnswer(answer.id);
      }
    } catch (e) {
      setState(() {
        final index = _answers.indexWhere((a) => a.id == answer.id);
        if (index != -1) {
          _answers[index] = answer;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update like: $e')),
        );
      }
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
            currentIndex: 1,
            onTap: (index) {
              if (index == 0) {
                Navigator.popUntil(context, (route) => route.isFirst);
              } else if (index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WriteScreen(),
                  ),
                );
              } else if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
              } else if (index == 4) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 24),
              Text(
                widget.quiz?.title ?? 'Feed',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      color: AppTheme.background,
      child: Column(
        children: [
          if (_categories.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildCategoryChips(),
          ],
          if (widget.quiz != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _buildSortTabs(),
            ),
            const SizedBox(height: 16),
          ] else
            const SizedBox(height: 16),
          Expanded(
            child: _buildAnswersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final category = isAll ? null : _categories[index - 1];
          final isActive = isAll
              ? _selectedCategoryId == null
              : _selectedCategoryId == category!.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onCategoryChanged(category?.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primaryStart : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isActive ? AppTheme.primaryStart : AppTheme.borderLight,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  isAll ? 'All' : category!.name,
                  style: TextStyle(
                    color: isActive ? Colors.white : AppTheme.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _sortTabs.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value.$1;
          final isActive = index == _selectedSortIndex;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onSortChanged(index),
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

  Widget _buildAnswersList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryStart),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.textLight),
            const SizedBox(height: 16),
            const Text(
              'Failed to load answers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnswers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_answers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: AppTheme.textLight),
            SizedBox(height: 16),
            Text(
              'No answers yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Be the first to answer!',
              style: TextStyle(color: AppTheme.textLight),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnswers,
      color: AppTheme.primaryStart,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _answers.length,
        itemBuilder: (context, index) {
          final answer = _answers[index];
          return AnswerCard(
            answer: answer,
            onLike: () => _toggleLike(answer),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnswerDetailScreen(answer: answer),
              ),
            ),
            onComment: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommentScreen(answer: answer),
              ),
            ),
            onUserTap: answer.user != null
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UserProfileScreen(userId: answer.userId),
                      ),
                    )
                : null,
          );
        },
      ),
    );
  }
}
