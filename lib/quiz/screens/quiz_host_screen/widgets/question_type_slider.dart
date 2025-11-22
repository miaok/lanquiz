import 'package:flutter/material.dart';

/// 题型数量滑块组件
class QuestionTypeSlider extends StatelessWidget {
  final String label;
  final int count;
  final ValueChanged<int> onChanged;
  final IconData icon;
  final Color color;

  const QuestionTypeSlider({
    super.key,
    required this.label,
    required this.count,
    required this.onChanged,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Slider(
              value: count.toDouble(),
              min: 0,
              max: 100,
              divisions: 10,
              activeColor: color,
              inactiveColor: color.withValues(alpha: 0.3),
              onChanged: (value) {
                onChanged(value.round());
              },
            ),
          ),
          Container(
            width: 28,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
