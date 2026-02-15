import 'package:flutter/material.dart';
import '../models/answer.dart';
import '../theme/app_theme.dart';

class AnswerCard extends StatelessWidget {
  final Answer answer;
  final VoidCallback? onLike;
  final VoidCallback? onTap;
  final VoidCallback? onComment;
  final VoidCallback? onUserTap;

  const AnswerCard({
    super.key,
    required this.answer,
    this.onLike,
    this.onTap,
    this.onComment,
    this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = answer.user;
    final avatarInitial = user?.avatarInitial ?? '?';
    final username = user?.displayName ?? '@unknown';
    final isLiked = answer.isLiked ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: onUserTap,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
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
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '⭐ ${answer.likeCount}',
                  style: const TextStyle(
                    color: AppTheme.likeRed,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                  left: BorderSide(color: AppTheme.primaryStart, width: 3),
                ),
              ),
              child: Text(
                answer.content,
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.borderLight, width: 1),
                ),
              ),
              child: Row(
                children: [
                  _ActionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    label: '${answer.likeCount}',
                    color: isLiked ? AppTheme.likeRed : AppTheme.textLight,
                    onTap: onLike,
                  ),
                  const SizedBox(width: 20),
                  _ActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: '${answer.commentCount}',
                    color: AppTheme.textLight,
                    onTap: onComment,
                  ),
                  const SizedBox(width: 20),
                  const _ActionButton(
                    icon: Icons.share,
                    label: 'Share',
                    color: AppTheme.textLight,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
