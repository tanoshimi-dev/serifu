import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/answer.dart';
import '../models/quiz.dart';
import '../repositories/answer_repository.dart';
import '../repositories/quiz_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';

class DesktopSidebar extends StatefulWidget {
  const DesktopSidebar({super.key});

  @override
  State<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends State<DesktopSidebar> {
  List<Answer> _rankings = [];
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSidebarData();
  }

  Future<void> _loadSidebarData() async {
    try {
      final results = await Future.wait([
        answerRepository.getRankings(period: 'daily', pageSize: 5),
        quizRepository.getCategories(),
      ]);
      if (mounted) {
        setState(() {
          _rankings = results[0] as List<Answer>;
          _categories = results[1] as List<Category>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: Colors.white,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryStart),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_rankings.isNotEmpty) ...[
                  _buildSectionTitle('Daily Rankings'),
                  const SizedBox(height: 12),
                  _buildRankingsList(),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => context.push('/rankings'),
                      child: const Text(
                        'See All Rankings',
                        style: TextStyle(
                          color: AppTheme.primaryStart,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (_categories.isNotEmpty) ...[
                  _buildSectionTitle('Categories'),
                  const SizedBox(height: 12),
                  _buildCategoriesList(),
                ],
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _buildRankingsList() {
    return Column(
      children: _rankings.asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final answer = entry.value;
        final user = answer.user;

        return GestureDetector(
          onTap: () => context.push('/answer/${answer.id}', extra: answer),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                _buildRankBadge(rank),
                const SizedBox(width: 8),
                UserAvatar(
                  avatarUrl: user?.avatar,
                  initial: user?.avatarInitial ?? '?',
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    answer.content,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
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
          ),
        );
      }).toList(),
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
      width: 22,
      height: 22,
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
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((category) {
        return GestureDetector(
          onTap: () => context.push('/category/${category.id}', extra: category),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryStart.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              category.name,
              style: const TextStyle(
                color: AppTheme.primaryStart,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
