import 'package:flutter/material.dart';
import '../../models/question.dart';

/// 题目卡片组件
class QuestionCard extends StatelessWidget {
  final String questionText;
  final QuestionType questionType;

  const QuestionCard({
    super.key,
    required this.questionText,
    required this.questionType,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 题目文本和题型标签在同一行
            RichText(
              text: TextSpan(
                children: [
                  // 题型标签
                  WidgetSpan(
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor(questionType, colorScheme),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        questionType.label,
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  // 题目文本
                  TextSpan(
                    text: questionText,
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
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

  Color _getTypeColor(QuestionType type, ColorScheme colorScheme) {
    switch (type) {
      case QuestionType.singleChoice:
        return colorScheme.primary;
      case QuestionType.trueFalse:
        return colorScheme.secondary;
      case QuestionType.multipleChoice:
        return colorScheme.tertiary;
    }
  }
}
