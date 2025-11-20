import 'package:flutter/material.dart';

class AnswerFeedbackOverlay extends StatelessWidget {
  final bool isCorrect;
  final bool isVisible;

  const AnswerFeedbackOverlay({
    super.key,
    required this.isCorrect,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: colorScheme.scrim.withValues(alpha: 0.54), // 半透明背景
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? colorScheme.tertiary : colorScheme.error,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                isCorrect ? '回答正确' : '回答错误',
                style: textTheme.headlineMedium?.copyWith(
                  color: isCorrect ? colorScheme.tertiary : colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
