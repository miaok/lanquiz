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
    return Card(
      color: Colors.blue[100],
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
                        color: _getTypeColor(questionType),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        questionType.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // 题目文本
                  TextSpan(
                    text: questionText,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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

  Color _getTypeColor(QuestionType type) {
    switch (type) {
      case QuestionType.singleChoice:
        return Colors.blue;
      case QuestionType.trueFalse:
        return Colors.orange;
      case QuestionType.multipleChoice:
        return Colors.purple;
    }
  }
}
