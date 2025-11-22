import 'package:flutter/material.dart';
import '../../../models/player_model.dart';

/// 获奖者卡片组件
class WinnerCard extends StatelessWidget {
  final QuizPlayer winner;
  final int rank;
  final bool isMainWinner;

  const WinnerCard({
    super.key,
    required this.winner,
    required this.rank,
    required this.isMainWinner,
  });

  @override
  Widget build(BuildContext context) {
    final (cardColor, accentColor, medalIcon) = _getRankColors(rank);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardColor, cardColor.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 左侧：排名和图标
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 排名标识
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '第$rank名',
                    style: TextStyle(
                      fontSize: isMainWinner ? 14 : 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 奖杯图标
                Icon(
                  medalIcon,
                  color: Colors.white,
                  size: isMainWinner ? 28 : 24,
                ),
              ],
            ),

            // 中间：玩家名称
            Expanded(
              child: Text(
                winner.name,
                style: TextStyle(
                  fontSize: isMainWinner ? 16 : 14,
                  fontWeight: isMainWinner ? FontWeight.bold : FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 右侧：得分
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${winner.score}分',
                style: TextStyle(
                  fontSize: isMainWinner ? 14 : 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 根据排名获取颜色和图标
  (Color, Color, IconData) _getRankColors(int rank) {
    return switch (rank) {
      1 => (
        const Color(0xFFFFB74D), // 金色
        const Color(0xFFFF8F00),
        Icons.emoji_events,
      ),
      2 => (
        const Color(0xFFBDBDBD), // 银色
        const Color(0xFF757575),
        Icons.emoji_events,
      ),
      _ => (
        const Color(0xFFBCAAA4), // 铜色
        const Color(0xFF6D4C41),
        Icons.emoji_events,
      ),
    };
  }
}
