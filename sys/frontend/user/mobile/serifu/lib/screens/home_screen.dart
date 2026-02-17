import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../models/answer.dart';
import '../models/user.dart';
import '../repositories/quiz_repository.dart';
import '../repositories/answer_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/notification_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/quiz_card_compact.dart';
import '../widgets/section_header.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/user_avatar.dart';
import 'quiz_detail_screen.dart';
import 'feed_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import 'answer_detail_screen.dart';
import 'user_profile_screen.dart';
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
  String? _selectedCategoryId;
  List<Answer> _rankings = [];
  User? _currentUser;
  int _unreadNotificationCount = 0;
  bool _isLoading = true;
  bool _isTrendingLoading = false;
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
        authRepository.getMe(),
        notificationRepository.getUnreadCount(),
      ]);
      setState(() {
        _quizzes = results[0] as List<Quiz>;
        _trendingAnswers = results[1] as List<Answer>;
        _categories = results[2] as List<Category>;
        _rankings = results[3] as List<Answer>;
        _currentUser = results[4] as User;
        _unreadNotificationCount = results[5] as int;
        _selectedCategoryId = null;
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
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FeedScreen(
            quiz: _quizzes.isNotEmpty ? _quizzes.first : null,
          ),
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
          builder: (context) => const NotificationScreen(),
        ),
      ).then((_) => _loadUnreadCount());
    } else if (index == 4) {
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

  Future<void> _loadUnreadCount() async {
    try {
      final count = await notificationRepository.getUnreadCount();
      setState(() => _unreadNotificationCount = count);
    } catch (_) {}
  }

  void _onCategoryChanged(String? categoryId) {
    if (categoryId == _selectedCategoryId) return;
    setState(() => _selectedCategoryId = categoryId);
    _loadTrendingByCategory();
  }

  Future<void> _loadTrendingByCategory() async {
    setState(() => _isTrendingLoading = true);

    try {
      final List<Answer> answers;
      if (_selectedCategoryId != null) {
        final quizzes = await quizRepository.getQuizzes(
          categoryId: _selectedCategoryId,
        );
        if (quizzes.isEmpty) {
          answers = [];
        } else {
          final answerLists = await Future.wait(
            quizzes.map((q) => answerRepository.getAnswersForQuiz(q.id, pageSize: 3)),
          );
          answers = answerLists.expand((list) => list).toList()
            ..sort((a, b) => b.likeCount.compareTo(a.likeCount));
        }
      } else {
        answers = await answerRepository.getTrendingAnswers(pageSize: 3);
      }
      setState(() {
        _trendingAnswers = answers;
        _isTrendingLoading = false;
      });
    } catch (e) {
      setState(() => _isTrendingLoading = false);
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
            notificationBadge: _unreadNotificationCount,
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
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      ).then((_) => _loadUnreadCount());
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                        if (_unreadNotificationCount > 0)
                          Positioned(
                            right: -6,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.likeRed,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 14),
                              child: Center(
                                child: Text(
                                  _unreadNotificationCount > 99 ? '99+' : '$_unreadNotificationCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Icon(Icons.person_outline, color: Colors.white, size: 24),
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
            const SizedBox(height: 16),
            if (_currentUser != null) ...[
              _buildStatsRow(),
              const SizedBox(height: 24),
            ],
            if (_quizzes.isNotEmpty) ...[
              SectionHeader(title: "Today's Quiz"),
              const SizedBox(height: 12),
              _buildQuizCarousel(),
              const SizedBox(height: 24),
            ],
            SectionHeader(title: 'Trending Answers'),
            if (_categories.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildTrendingCategoryChips(),
            ],
            const SizedBox(height: 12),
            _buildTrendingQuotes(),
            const SizedBox(height: 24),
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

  Widget _buildStatsRow() {
    final user = _currentUser!;
    final rankIndex = _rankings.indexWhere((a) => a.userId == user.id);
    final rankLabel = rankIndex != -1 ? '#${rankIndex + 1}' : '#—';

    final stats = [
      (icon: Icons.edit_note, value: '${user.answerCount ?? 0}', label: 'Answers'),
      (icon: Icons.favorite, value: '${user.totalLikes}', label: 'Likes'),
      (icon: Icons.people, value: '${user.followerCount ?? 0}', label: 'Followers'),
      (icon: Icons.emoji_events, value: rankLabel, label: 'Ranking'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: stats.map((stat) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: stat != stats.last ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
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
              child: Column(
                children: [
                  Icon(stat.icon, color: AppTheme.primaryStart, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    stat.value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textGray,
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

  Widget _buildTrendingCategoryChips() {
    return SizedBox(
      height: 32,
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
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primaryStart : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive ? AppTheme.primaryStart : AppTheme.borderLight,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  isAll ? 'All' : category!.name,
                  style: TextStyle(
                    color: isActive ? Colors.white : AppTheme.textGray,
                    fontSize: 12,
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

  Widget _buildTrendingQuotes() {
    if (_isTrendingLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: AppTheme.primaryStart,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (_trendingAnswers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(
          'No trending answers yet',
          style: TextStyle(
            color: AppTheme.textLight,
            fontSize: 13,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _trendingAnswers.map((answer) {
          final user = answer.user;
          final avatarInitial = user?.avatarInitial ?? '?';

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
                  Expanded(
                    child: Text(
                      '「${answer.content}」',
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      UserAvatar(
                        avatarUrl: user?.avatar,
                        initial: avatarInitial,
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${answer.likeCount}',
                        style: const TextStyle(
                          color: AppTheme.likeRed,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
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
                    child: UserAvatar(
                      avatarUrl: user?.avatar,
                      initial: avatarInitial,
                      size: 36,
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
