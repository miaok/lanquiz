import 'package:flutter/material.dart';
import '../../../services/quiz_record_service.dart';
import 'statistics_item.dart';

/// 统计信息卡片组件
class StatisticsCard extends StatelessWidget {
  final GameStatistics statistics;

  const StatisticsCard({super.key, required this.statistics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '统计信息',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StatisticsItem(
                  label: '总对局',
                  value: statistics.totalGames.toString(),
                  icon: Icons.gamepad,
                  color: colorScheme.primary,
                ),
                StatisticsItem(
                  label: '胜利',
                  value: statistics.wins.toString(),
                  icon: Icons.emoji_events,
                  color: colorScheme.tertiary,
                ),
                StatisticsItem(
                  label: '失败',
                  value: statistics.losses.toString(),
                  icon: Icons.trending_down,
                  color: colorScheme.error,
                ),
                StatisticsItem(
                  label: '平局',
                  value: statistics.draws.toString(),
                  icon: Icons.compare_arrows,
                  color: colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.percent, color: colorScheme.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Text(
                    '胜率: ${statistics.winRate.toStringAsFixed(1)}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
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
}
