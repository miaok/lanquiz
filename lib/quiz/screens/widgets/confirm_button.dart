import 'package:flutter/material.dart';

/// 多选题确认按钮组件
class ConfirmButton extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final VoidCallback? onConfirm;

  const ConfirmButton({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FilledButton(
      onPressed: selectedCount == 0 ? null : onConfirm,
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.tertiary,
        disabledBackgroundColor: colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.all(16),
      ),
      child: Text(
        '确认答案 ($selectedCount/$totalCount)',
        style: textTheme.labelLarge?.copyWith(
          color: selectedCount == 0 ? null : colorScheme.onTertiary,
        ),
      ),
    );
  }
}
