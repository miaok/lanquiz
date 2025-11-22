import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game_record.dart';
import '../services/quiz_record_service.dart';

/// 游戏记录列表页面
class GameRecordsScreen extends StatefulWidget {
  const GameRecordsScreen({super.key});

  @override
  State<GameRecordsScreen> createState() => _GameRecordsScreenState();
}

class _GameRecordsScreenState extends State<GameRecordsScreen> {
  final GameRecordService _service = GameRecordService();
  List<GameRecord> _records = [];
  GameStatistics? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  /// 加载记录和统计信息
  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);

    try {
      final records = await _service.getRecords();
      final statistics = await _service.getStatistics();

      setState(() {
        _records = records;
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载记录失败: $e')));
      }
    }
  }

  /// 删除记录
  Future<void> _deleteRecord(String recordId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.deleteRecord(recordId);
      _loadRecords();
    }
  }

  /// 清空所有记录
  Future<void> _clearAllRecords() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有记录吗？此操作不可恢复！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.clearAllRecords();
      _loadRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    //final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('对战记录'),
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: '清空所有记录',
              onPressed: _clearAllRecords,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadRecords,
              child: CustomScrollView(
                slivers: [
                  // 统计信息卡片
                  if (_statistics != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildStatisticsCard(_statistics!),
                      ),
                    ),

                  // 记录列表
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final record = _records[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildRecordCard(record),
                        );
                      }, childCount: _records.length),
                    ),
                  ),

                  // 底部间距
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
              ),
            ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无对战记录',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '开始一场游戏来创建记录吧！',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计信息卡片
  Widget _buildStatisticsCard(GameStatistics stats) {
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
                _buildStatItem(
                  '总对局',
                  stats.totalGames.toString(),
                  Icons.gamepad,
                  colorScheme.primary,
                ),
                _buildStatItem(
                  '胜利',
                  stats.wins.toString(),
                  Icons.emoji_events,
                  colorScheme.tertiary,
                ),
                _buildStatItem(
                  '失败',
                  stats.losses.toString(),
                  Icons.trending_down,
                  colorScheme.error,
                ),
                _buildStatItem(
                  '平局',
                  stats.draws.toString(),
                  Icons.compare_arrows,
                  colorScheme.secondary,
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
                    '胜率: ${stats.winRate.toStringAsFixed(1)}%',
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

  /// 构建统计项
  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// 构建记录卡片
  Widget _buildRecordCard(GameRecord record) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    // 根据结果选择颜色
    Color resultColor;
    IconData resultIcon;
    String resultText;

    switch (record.result) {
      case GameResult.win:
        resultColor = colorScheme.tertiary;
        resultIcon = Icons.emoji_events;
        resultText = '胜利';
        break;
      case GameResult.lose:
        resultColor = colorScheme.error;
        resultIcon = Icons.trending_down;
        resultText = '失败';
        break;
      case GameResult.draw:
        resultColor = colorScheme.secondary;
        resultIcon = Icons.compare_arrows;
        resultText = '平局';
        break;
    }

    return Card(
      child: InkWell(
        onLongPress: () => _deleteRecord(record.id),
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
                    child: _buildPlayerInfo(
                      record.hostName,
                      record.hostScore,
                      record.result == GameResult.win,
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
                    child: _buildPlayerInfo(
                      record.clientName,
                      record.clientScore,
                      record.result == GameResult.lose,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 额外信息
              Wrap(
                spacing: 12,
                children: [
                  _buildInfoChip(Icons.quiz, '${record.totalQuestions} 题'),
                  _buildInfoChip(
                    Icons.timer,
                    _formatDuration(record.durationSeconds),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建玩家信息
  Widget _buildPlayerInfo(String name, int score, bool isWinner) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWinner
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: isWinner
            ? Border.all(color: colorScheme.primary, width: 2)
            : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isWinner)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.emoji_events,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                ),
              Flexible(
                child: Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            score.toString(),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: isWinner ? colorScheme.primary : colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息芯片
  Widget _buildInfoChip(IconData icon, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化时长
  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '$minutes分$secs秒';
  }
}
