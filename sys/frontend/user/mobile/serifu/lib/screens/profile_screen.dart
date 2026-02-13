import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/answer.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_card.dart';
import '../widgets/bottom_nav_bar.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  List<Answer> _answers = [];
  bool _isLoading = true;
  String? _error;
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await authRepository.getMe();
      final answers = await userRepository.getUserAnswers(user.id);
      setState(() {
        _user = user;
        _answers = answers;
        _nameController.text = user.name;
        _bioController.text = user.bio ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_user == null) return;

    try {
      final updated = await userRepository.updateUser(
        _user!.id,
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
      );
      setState(() {
        _user = updated;
        _isEditing = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await authService.clearAuth();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  if (!_isEditing)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      child: const Icon(Icons.edit, color: Colors.white, size: 22),
                    )
                  else
                    GestureDetector(
                      onTap: _saveProfile,
                      child: const Icon(Icons.check, color: Colors.white, size: 22),
                    ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _logout,
                    child: const Icon(Icons.logout, color: Colors.white, size: 22),
                  ),
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
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfile,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final user = _user!;

    return Container(
      color: AppTheme.background,
      child: RefreshIndicator(
        onRefresh: _loadProfile,
        color: AppTheme.primaryStart,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildUserInfo(user),
            const SizedBox(height: 24),
            _buildStats(user),
            const SizedBox(height: 24),
            if (_isEditing) ...[
              _buildEditForm(),
              const SizedBox(height: 24),
            ],
            if (_answers.isNotEmpty) ...[
              const Text(
                'My Answers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              ..._answers.map((answer) => AnswerCard(answer: answer)),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: const [
                      Icon(Icons.edit_note, size: 48, color: AppTheme.textLight),
                      SizedBox(height: 12),
                      Text(
                        'No answers yet',
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

  Widget _buildUserInfo(User user) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              user.avatarInitial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 32,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          user.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textGray,
          ),
        ),
        if (user.bio != null && user.bio!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            user.bio!,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildStats(User user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('${user.followerCount ?? 0}', 'Followers'),
        _buildStatItem('${user.followingCount ?? 0}', 'Following'),
        _buildStatItem('${user.answerCount ?? 0}', 'Answers'),
      ],
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

  Widget _buildEditForm() {
    return Container(
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
          const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bioController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Bio',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _nameController.text = _user?.name ?? '';
                    _bioController.text = _user?.bio ?? '';
                  });
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
