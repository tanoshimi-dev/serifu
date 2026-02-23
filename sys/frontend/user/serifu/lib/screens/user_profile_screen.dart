import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../api/api_client.dart';
import '../models/user.dart';
import '../models/answer.dart';
import '../repositories/user_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_card.dart';
import '../widgets/user_avatar.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  User? _user;
  List<Answer> _answers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.userId == apiClient.userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/profile');
      });
    } else {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        userRepository.getUser(widget.userId),
        userRepository.getUserAnswers(widget.userId),
      ]);
      setState(() {
        _user = results[0] as User;
        _answers = results[1] as List<Answer>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_user == null) return;

    final isFollowing = _user!.isFollowing ?? false;
    final prevUser = _user!;

    setState(() {
      _user = _user!.copyWith(
        isFollowing: !isFollowing,
        followerCount: (_user!.followerCount ?? 0) + (isFollowing ? -1 : 1),
      );
    });

    try {
      if (isFollowing) {
        await userRepository.unfollowUser(widget.userId);
      } else {
        await userRepository.followUser(widget.userId);
      }
    } catch (e) {
      setState(() => _user = prevUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作に失敗しました: $e')),
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
          Expanded(child: _buildContent()),
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
                onTap: () => context.pop(),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _user?.name ?? '',
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
              'プロフィールの読み込みに失敗しました',
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
              onPressed: _loadProfile,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    final user = _user!;
    final isFollowing = user.isFollowing ?? false;

    return Container(
      color: AppTheme.background,
      child: RefreshIndicator(
        onRefresh: _loadProfile,
        color: AppTheme.primaryStart,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Avatar
            Center(
              child: UserAvatar(
                avatarUrl: user.avatar,
                initial: user.avatarInitial,
                size: 80,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                user.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            if (user.bio != null && user.bio!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  user.bio!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textGray,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Follow button
            Center(
              child: GestureDetector(
                onTap: _toggleFollow,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isFollowing ? null : AppTheme.primaryGradient,
                    color: isFollowing ? Colors.white : null,
                    borderRadius: BorderRadius.circular(24),
                    border: isFollowing
                        ? Border.all(color: AppTheme.primaryStart, width: 2)
                        : null,
                  ),
                  child: Text(
                    isFollowing ? 'フォロー中' : 'フォローする',
                    style: TextStyle(
                      color: isFollowing ? AppTheme.primaryStart : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () => context.push('/user/${widget.userId}/followers'),
                  behavior: HitTestBehavior.opaque,
                  child: _buildStatItem('${user.followerCount ?? 0}', 'フォロワー'),
                ),
                GestureDetector(
                  onTap: () => context.push('/user/${widget.userId}/following'),
                  behavior: HitTestBehavior.opaque,
                  child: _buildStatItem('${user.followingCount ?? 0}', 'フォロー中'),
                ),
                _buildStatItem('${user.answerCount ?? 0}', '回答'),
              ],
            ),
            const SizedBox(height: 24),

            // Answers
            if (_answers.isNotEmpty) ...[
              const Text(
                '回答一覧',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              ..._answers.map((answer) => AnswerCard(
                    answer: answer,
                    onTap: () => context.push('/answer/${answer.id}', extra: answer),
                    onComment: () => context.push('/answer/${answer.id}/comments', extra: answer),
                  )),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: const [
                      Icon(Icons.edit_note, size: 48, color: AppTheme.textLight),
                      SizedBox(height: 12),
                      Text(
                        'まだ回答がありません',
                        style: TextStyle(
                          color: AppTheme.textGray,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textGray,
          ),
        ),
      ],
    );
  }
}
