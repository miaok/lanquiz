import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/game_record.dart';
import 'player_info_box.dart';
import 'info_chip.dart';

/// 记录卡片组件
class RecordCard extends StatelessWidget {
  final GameRecord record;
  final VoidCallback onLongPress;

  const RecordCard({
    super.key,
    required this.record,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    final (resultColor, resultIcon, resultText) = _getResultStyle(colorScheme);

    return Card(
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：时间和结果
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(record.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: resultColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: resultColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(resultIcon, size: 16, color: resultColor),
                        const SizedBox(width: 4),
                        Text(
                          resultText,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: resultColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 玩家信息和分数
              Row(
                children: [
                  Expanded(
                    child: PlayerInfoBox(
                      name: record.hostName,
                      score: record.hostScore,
                      isWinner: record.result == GameResult.win,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'VS',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.outline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: PlayerInfoBox(
                      name: record.clientName,
                      score: record.clientScore,
                      isWinner: record.result == GameResult.lose,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 额外信息
              Wrap(
                spacing: 12,
                children: [
                  InfoChip(
                    icon: Icons.quiz,
                    text: '${record.totalQuestions} 题',
                  ),
                  InfoChip(
                    icon: Icons.timer,
                    text: _formatDuration(record.durationSeconds),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 获取结果样式
  (Color, IconData, String) _getResultStyle(ColorScheme colorScheme) {
    return switch (record.result) {
      GameResult.win => (colorScheme.tertiary, Icons.emoji_events, '胜利'),
      GameResult.lose => (colorScheme.error, Icons.trending_down, '失败'),
      GameResult.draw => (colorScheme.secondary, Icons.compare_arrows, '平局'),
    };
  }

  /// 格式化时长
  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '$minutes分$secs秒';
  }
}
