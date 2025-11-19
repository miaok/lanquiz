import 'package:flutter/material.dart';
import '../../models/question.dart';

/// 选项按钮组件
/// 根据题型（单选/判断/多选）渲染不同样式的选项
class OptionButton extends StatelessWidget {
  final Question question;
  final int index;
  final bool hasAnswered;
  final int? selectedAnswer;
  final List<int> selectedAnswers;
  final VoidCallback onSelectSingle;
  final VoidCallback onToggleMultiple;

  const OptionButton({
    super.key,
    required this.question,
    required this.index,
    required this.hasAnswered,
    this.selectedAnswer,
    this.selectedAnswers = const [],
    required this.onSelectSingle,
    required this.onToggleMultiple,
  });

  @override
  Widget build(BuildContext context) {
    // 根据题型渲染不同的按钮
    switch (question.type) {
      case QuestionType.singleChoice:
      case QuestionType.trueFalse:
        return _buildSingleChoiceOption();
      case QuestionType.multipleChoice:
        return _buildMultipleChoiceOption();
    }
  }

  // 单选题/判断题选项
  Widget _buildSingleChoiceOption() {
    final isSelected = selectedAnswer == index;

    Color? backgroundColor;
    Color? borderColor;

    if (isSelected) {
      // 已选择但未提交或已提交
      backgroundColor = Colors.blue[100];
      borderColor = Colors.blue;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: OutlinedButton(
        onPressed: hasAnswered || isSelected ? null : onSelectSingle,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor ?? Colors.grey, width: 2),
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                question.options[index],
                style: const TextStyle(fontSize: 20, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 多选题选项
  Widget _buildMultipleChoiceOption() {
    final isSelected = selectedAnswers.contains(index);

    Color? backgroundColor;
    Color? borderColor;

    if (isSelected) {
      backgroundColor = Colors.blue[100];
      borderColor = Colors.blue;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton(
        onPressed: hasAnswered ? null : onToggleMultiple,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor ?? Colors.grey, width: 2),
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                question.options[index],
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
