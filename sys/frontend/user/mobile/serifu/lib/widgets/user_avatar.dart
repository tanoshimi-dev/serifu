import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String initial;
  final double size;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.initial,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      final url = avatarUrl!;
      final fullUrl = url.startsWith('http://') || url.startsWith('https://')
          ? url
          : '${ApiClient.serverBaseUrl}$url';
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          fullUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        ),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}
