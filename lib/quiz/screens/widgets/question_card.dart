import 'package:flutter/material.dart';

/// 题目卡片组件
class QuestionCard extends StatelessWidget {
  final String questionText;

  const QuestionCard({super.key, required this.questionText});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue[100],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          questionText,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
