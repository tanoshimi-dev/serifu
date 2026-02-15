import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/answer.dart';
import '../repositories/answer_repository.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import 'comment_screen.dart';
import 'user_profile_screen.dart';

class AnswerDetailScreen extends StatefulWidget {
  final Answer answer;

  const AnswerDetailScreen({
    super.key,
    required this.answer,
  });

  @override
  State<AnswerDetailScreen> createState() => _AnswerDetailScreenState();
}

class _AnswerDetailScreenState extends State<AnswerDetailScreen> {
  late Answer _answer;
  bool _isEditing = false;
  final _editController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _answer = widget.answer;
    _editController.text = _answer.content;
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  bool get _isOwner => _answer.userId == apiClient.userId;

  Future<void> _toggleLike() async {
    final isLiked = _answer.isLiked ?? false;
    final newLikeCount = isLiked ? _answer.likeCount - 1 : _answer.likeCount + 1;

    final previous = _answer;
    setState(() {
      _answer = _answer.copyWith(likeCount: newLikeCount, isLiked: !isLiked);
    });

    try {
      if (isLiked) {
        await answerRepository.unlikeAnswer(_answer.id);
      } else {
        await answerRepository.likeAnswer(_answer.id);
      }
    } catch (e) {
      setState(() => _answer = previous);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update like: $e')),
        );
      }
    }
  }

  Future<void> _deleteAnswer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('回答を削除'),
        content: const Text('この回答を削除しますか？この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.likeRed),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await answerRepository.deleteAnswer(_answer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('回答を削除しました')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _saveEdit() async {
    final content = _editController.text.trim();
    if (content.isEmpty) return;

    try {
      final updated = await answerRepository.updateAnswer(_answer.id, content);
      setState(() {
        _answer = updated;
        _isEditing = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('編集に失敗しました: $e')),
        );
      }
    }
  }

  void _navigateToComments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(answer: _answer),
      ),
    );
  }

  void _navigateToUser() {
    if (_answer.user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(userId: _answer.userId),
      ),
    );
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
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  '回答詳細',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_isOwner)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
                  onSelected: (value) {
                    if (value == 'edit') {
                      setState(() {
                        _isEditing = true;
                        _editController.text = _answer.content;
                      });
                    } else if (value == 'delete') {
                      _deleteAnswer();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('編集')),
                    const PopupMenuItem(value: 'delete', child: Text('削除')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final user = _answer.user;
    final isLiked = _answer.isLiked ?? false;

    return Container(
      color: AppTheme.background,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // User info
          GestureDetector(
            onTap: _navigateToUser,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user?.avatarInitial ?? '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeAgo(_answer.createdAt),
                      style: const TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Answer content
          if (_isEditing) ...[
            TextField(
              controller: _editController,
              maxLines: 5,
              maxLength: 150,
              decoration: InputDecoration(
                hintText: '回答を入力...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveEdit,
                  child: const Text('保存'),
                ),
              ],
            ),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: const Border(
                  left: BorderSide(color: AppTheme.primaryStart, width: 3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _answer.content,
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 17,
                  height: 1.7,
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Stats
          Container(
            padding: const EdgeInsets.all(16),
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  value: '${_answer.likeCount}',
                  label: 'いいね',
                  color: isLiked ? AppTheme.likeRed : AppTheme.textLight,
                  onTap: _toggleLike,
                ),
                _StatItem(
                  icon: Icons.chat_bubble_outline,
                  value: '${_answer.commentCount}',
                  label: 'コメント',
                  color: AppTheme.textLight,
                  onTap: _navigateToComments,
                ),
                _StatItem(
                  icon: Icons.visibility_outlined,
                  value: '${_answer.viewCount}',
                  label: '閲覧',
                  color: AppTheme.textLight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textGray,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
