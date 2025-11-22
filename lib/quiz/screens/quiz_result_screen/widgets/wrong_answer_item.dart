import 'package:flutter/material.dart';
import '../../../models/question.dart';

/// 错题项组件
class WrongAnswerItem extends StatelessWidget {
  final Map<String, dynamic> wrongAnswer;
  final Question question;

  const WrongAnswerItem({
    super.key,
    required this.wrongAnswer,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final playerAnswer = wrongAnswer['playerAnswer'];
    final correctAnswer = wrongAnswer['correctAnswer'];

    final playerAnswerText = _formatAnswer(question, playerAnswer);
    final correctAnswerText = _formatAnswer(question, correctAnswer);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 题型标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTypeColor(question.type, colorScheme),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question.type.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question.question,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('你的答案: ', style: TextStyle(color: colorScheme.outline)),
              Expanded(
                child: Text(
                  playerAnswerText,
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('正确答案: ', style: TextStyle(color: colorScheme.outline)),
              Expanded(
                child: Text(
                  correctAnswerText,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 获取题型颜色
  Color _getTypeColor(QuestionType type, ColorScheme colorScheme) {
    return switch (type) {
      QuestionType.singleChoice => colorScheme.primary,
      QuestionType.trueFalse => colorScheme.tertiary,
      QuestionType.multipleChoice => colorScheme.secondary,
    };
  }

  /// 格式化答案
  String _formatAnswer(Question question, dynamic answer) {
    if (answer == null) return '未作答';

    try {
      if (answer is int) {
        if (answer >= 0 && answer < question.options.length) {
          return question.options[answer];
        }
      } else if (answer is List) {
        final indices = answer.cast<int>()..sort();
        return indices
            .map(
              (i) => (i >= 0 && i < question.options.length)
                  ? question.options[i]
                  : '?',
            )
            .join(', ');
      }
    } catch (e) {
      return answer.toString();
    }
    return answer.toString();
  }
}
