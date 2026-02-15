import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../models/answer.dart';
import '../repositories/quiz_repository.dart';
import '../repositories/answer_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/quiz_card_compact.dart';
import '../widgets/answer_card.dart';
import '../widgets/section_header.dart';
import '../widgets/bottom_nav_bar.dart';
import 'quiz_detail_screen.dart';
import 'feed_screen.dart';
import 'profile_screen.dart';
import 'answer_detail_screen.dart';
import 'comment_screen.dart';
import 'user_profile_screen.dart';
import 'category_quizzes_screen.dart';
import 'rankings_screen.dart';
import 'write_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  List<Quiz> _quizzes = [];
  List<Answer> _trendingAnswers = [];
  List<Category> _categories = [];
  List<Answer> _rankings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        quizRepository.getDailyQuizzes(),
        answerRepository.getTrendingAnswers(pageSize: 3),
        quizRepository.getCategories(),
        answerRepository.getRankings(period: 'daily', pageSize: 3),
      ]);
      setState(() {
        _quizzes = results[0] as List<Quiz>;
        _trendingAnswers = results[1] as List<Answer>;
        _categories = results[2] as List<Category>;
        _rankings = results[3] as List<Answer>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onNavTap(int index) {
    if (index == 1 && _quizzes.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FeedScreen(quiz: _quizzes.first),
        ),
      );
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
          builder: (context) => const ProfileScreen(),
        ),
      );
    } else {
      setState(() {
        _currentNavIndex = index;
      });
    }
  }

  Future<void> _toggleLike(Answer answer) async {
    final isLiked = answer.isLiked ?? false;
    final newLikeCount = isLiked ? answer.likeCount - 1 : answer.likeCount + 1;

    setState(() {
      final index = _trendingAnswers.indexWhere((a) => a.id == answer.id);
      if (index != -1) {
        _trendingAnswers[index] = answer.copyWith(
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
        final index = _trendingAnswers.indexWhere((a) => a.id == answer.id);
        if (index != -1) {
          _trendingAnswers[index] = answer;
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
              'Failed to load dashboard',
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
              onPressed: _loadDashboard,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppTheme.background,
      child: RefreshIndicator(
        onRefresh: _loadDashboard,
        color: AppTheme.primaryStart,
        child: ListView(
          padding: const EdgeInsets.only(top: 20, bottom: 20),
          children: [
            _buildGreeting(),
            const SizedBox(height: 24),
            if (_quizzes.isNotEmpty) ...[
              SectionHeader(title: "Today's Quiz"),
              const SizedBox(height: 12),
              _buildQuizCarousel(),
              const SizedBox(height: 24),
            ],
            if (_trendingAnswers.isNotEmpty) ...[
              SectionHeader(title: 'Trending Answers'),
              const SizedBox(height: 12),
              _buildTrendingAnswers(),
              const SizedBox(height: 24),
            ],
            if (_categories.isNotEmpty) ...[
              SectionHeader(title: 'Categories'),
              const SizedBox(height: 12),
              _buildCategoryGrid(),
              const SizedBox(height: 24),
            ],
            if (_rankings.isNotEmpty) ...[
              SectionHeader(
                title: 'Daily Rankings',
                onSeeAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RankingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildRankings(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "What's your best serifu today?",
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCarousel() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _quizzes.length,
        itemBuilder: (context, index) {
          final quiz = _quizzes[index];
          return QuizCardCompact(
            quiz: quiz,
            onTap: () => _navigateToQuizDetail(quiz),
          );
        },
      ),
    );
  }

  Widget _buildTrendingAnswers() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _trendingAnswers.map((answer) {
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
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _categories.map((category) {
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CategoryQuizzesScreen(category: category),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                category.name,
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRankings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _rankings.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final answer = entry.value;
          final user = answer.user;
          final avatarInitial = user?.avatarInitial ?? '?';
          final username = user?.displayName ?? '@unknown';

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnswerDetailScreen(answer: answer),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildRankBadge(rank),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: user != null
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserProfileScreen(userId: answer.userId),
                              ),
                            )
                        : null,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          avatarInitial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          answer.content,
                          style: const TextStyle(
                            color: AppTheme.textGray,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${answer.likeCount}',
                    style: const TextStyle(
                      color: AppTheme.likeRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];
    final color = rank <= 3 ? colors[rank - 1] : AppTheme.textLight;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
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
