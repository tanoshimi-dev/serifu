import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../theme/app_theme.dart';
import 'feed_screen.dart';

class QuizDetailScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizDetailScreen({
    super.key,
    required this.quiz,
  });

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  final TextEditingController _answerController = TextEditingController();
  static const int maxCharacters = 150;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
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
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
              Text(
                'Quiz ${widget.quiz.number}/${widget.quiz.totalQuizzes}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
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
    return Container(
      color: AppTheme.background,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '🎭 「${widget.quiz.title}」',
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
              widget.quiz.situation,
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
              widget.quiz.requirement,
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
              '👥 ${widget.quiz.answerCount} people answered',
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
      onTap: () {
        // TODO: Submit answer
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FeedScreen(quiz: widget.quiz),
          ),
        );
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
