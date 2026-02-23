import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../api/api_client.dart';
import '../models/quiz.dart';
import '../repositories/answer_repository.dart';
import '../repositories/quiz_repository.dart';
import '../theme/app_theme.dart';

class QuizDetailScreen extends StatefulWidget {
  final String quizId;
  final Quiz? quiz;

  const QuizDetailScreen({
    super.key,
    required this.quizId,
    this.quiz,
  });

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  final TextEditingController _answerController = TextEditingController();
  static const int maxCharacters = 150;
  bool _isSubmitting = false;
  Quiz? _quiz;
  bool _isLoadingQuiz = false;
  String? _quizError;

  @override
  void initState() {
    super.initState();
    if (widget.quiz != null) {
      _quiz = widget.quiz;
    } else {
      _loadQuiz();
    }
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoadingQuiz = true;
      _quizError = null;
    });

    try {
      final quiz = await quizRepository.getQuiz(widget.quizId);
      setState(() {
        _quiz = quiz;
        _isLoadingQuiz = false;
      });
    } catch (e) {
      setState(() {
        _quizError = e.toString();
        _isLoadingQuiz = false;
      });
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    final content = _answerController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your answer')),
      );
      return;
    }

    if (apiClient.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to submit an answer')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await answerRepository.createAnswer(_quiz!.id, content);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Answer submitted successfully!')),
        );
        _answerController.clear();
        context.push('/feed', extra: _quiz);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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
              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _quiz?.title ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const Icon(Icons.more_horiz, color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoadingQuiz) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryStart),
      );
    }

    if (_quizError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.textLight),
            const SizedBox(height: 16),
            Text(
              _quizError!,
              style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQuiz,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final quiz = _quiz!;

    return Container(
      color: AppTheme.background,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '🎭 「${quiz.title}」',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('📖 シチュエーション'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              quiz.description,
              style: const TextStyle(
                color: AppTheme.textGray,
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('✨ 求められるセリフ'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warningBackground,
              borderRadius: BorderRadius.circular(8),
              border: const Border(
                left: BorderSide(color: AppTheme.warningBorder, width: 4),
              ),
            ),
            child: Text(
              quiz.requirement,
              style: const TextStyle(
                color: AppTheme.warningText,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _answerController,
            maxLines: 5,
            maxLength: maxCharacters,
            enabled: !_isSubmitting,
            decoration: InputDecoration(
              hintText: 'あなたの回答をここに入力...',
              hintStyle: const TextStyle(color: AppTheme.textLight),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryStart, width: 2),
              ),
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_answerController.text.length} / $maxCharacters 文字',
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildSubmitButton(),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '👥 ${quiz.answerCount} people answered',
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildViewAnswersButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(left: 8),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppTheme.primaryStart, width: 4),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.textDark,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isSubmitting ? null : _submitAnswer,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: _isSubmitting ? null : AppTheme.primaryGradient,
          color: _isSubmitting ? Colors.grey : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: _isSubmitting
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            : const Text(
                'Submit Answer',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildViewAnswersButton() {
    return GestureDetector(
      onTap: () {
        context.push('/feed', extra: _quiz);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryStart, width: 2),
        ),
        child: const Text(
          'See Other Answers',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.primaryStart,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
