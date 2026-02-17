import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../repositories/notification_repository.dart';
import '../repositories/answer_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/user_avatar.dart';
import 'home_screen.dart';
import 'feed_screen.dart';
import 'write_screen.dart';
import 'profile_screen.dart';
import 'answer_detail_screen.dart';
import 'user_profile_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notifications = await notificationRepository.getNotifications();
      await notificationRepository.markAllAsRead();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _onNotificationTap(AppNotification notification) async {
    if (notification.type == 'follow') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(userId: notification.actorId),
        ),
      );
    } else if (notification.targetType == 'answer') {
      try {
        final answer = await answerRepository.getAnswer(notification.targetId);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnswerDetailScreen(answer: answer),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load answer: $e')),
          );
        }
      }
    }
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FeedScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WriteScreen()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent()),
          BottomNavBar(
            currentIndex: 3,
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
            children: const [
              Icon(Icons.notifications, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Notifications',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
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
            const Text(
              'Failed to load notifications',
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
              onPressed: _loadNotifications,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 48, color: AppTheme.textLight),
            SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'When someone likes, comments, or follows you,\nyou\'ll see it here.',
              style: TextStyle(color: AppTheme.textLight, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppTheme.background,
      child: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: AppTheme.primaryStart,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _notifications.length,
          itemBuilder: (context, index) {
            return _buildNotificationItem(_notifications[index]);
          },
        ),
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    final avatarInitial = notification.actor?.avatarInitial ?? '?';

    IconData typeIcon;
    Color typeColor;
    switch (notification.type) {
      case 'like':
        typeIcon = Icons.favorite;
        typeColor = AppTheme.likeRed;
        break;
      case 'comment':
        typeIcon = Icons.chat_bubble;
        typeColor = AppTheme.primaryStart;
        break;
      case 'follow':
        typeIcon = Icons.person_add;
        typeColor = const Color(0xFF4CAF50);
        break;
      default:
        typeIcon = Icons.notifications;
        typeColor = AppTheme.textLight;
    }

    return GestureDetector(
      onTap: () => _onNotificationTap(notification),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar(
                  avatarUrl: notification.actor?.avatar,
                  initial: avatarInitial,
                  size: 44,
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: typeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Icon(typeIcon, color: Colors.white, size: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textDark,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.timeAgo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
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
