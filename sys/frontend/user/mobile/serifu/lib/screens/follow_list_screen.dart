import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';

class FollowListScreen extends StatefulWidget {
  final String userId;
  final bool isFollowers;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.isFollowers,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _page = 1;
    });

    try {
      final users = widget.isFollowers
          ? await userRepository.getFollowers(widget.userId, page: 1)
          : await userRepository.getFollowing(widget.userId, page: 1);
      setState(() {
        _users = users;
        _hasMore = users.length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _page + 1;
      final users = widget.isFollowers
          ? await userRepository.getFollowers(widget.userId, page: nextPage)
          : await userRepository.getFollowing(widget.userId, page: nextPage);
      setState(() {
        _users.addAll(users);
        _page = nextPage;
        _hasMore = users.length >= 20;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('読み込みに失敗しました: $e')),
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
              Text(
                widget.isFollowers ? 'フォロワー' : 'フォロー中',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
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
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 48, color: AppTheme.textLight),
            const SizedBox(height: 16),
            Text(
              widget.isFollowers ? 'フォロワーはまだいません' : 'フォロー中のユーザーはいません',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppTheme.background,
      child: RefreshIndicator(
        onRefresh: _loadUsers,
        color: AppTheme.primaryStart,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: _users.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _users.length) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _isLoadingMore
                      ? const CircularProgressIndicator(color: AppTheme.primaryStart)
                      : TextButton(
                          onPressed: _loadMore,
                          child: const Text('もっと見る'),
                        ),
                ),
              );
            }

            final user = _users[index];
            return _buildUserItem(user);
          },
        ),
      ),
    );
  }

  Widget _buildUserItem(User user) {
    return GestureDetector(
      onTap: () {
        context.push('/user/${user.id}');
      },
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
            UserAvatar(
              avatarUrl: user.avatar,
              initial: user.avatarInitial,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppTheme.textDark,
                    ),
                  ),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.bio!,
                      style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textLight, size: 20),
          ],
        ),
      ),
    );
  }
}
