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
    return ElevatedButton(
      onPressed: selectedCount == 0 ? null : onConfirm,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        '确认答案 ($selectedCount/$totalCount)',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
