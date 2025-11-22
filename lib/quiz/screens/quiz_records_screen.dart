import 'package:flutter/material.dart';
import '../models/game_record.dart';
import '../services/quiz_record_service.dart';
import 'quiz_records_screen/widgets/empty_state.dart';
import 'quiz_records_screen/widgets/statistics_card.dart';
import 'quiz_records_screen/widgets/record_card.dart';

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
        _showErrorSnackBar('加载记录失败: $e');
      }
    }
  }

  /// 删除记录
  Future<void> _deleteRecord(String recordId) async {
    final confirmed = await _showDeleteConfirmDialog();

    if (confirmed == true) {
      await _service.deleteRecord(recordId);
      _loadRecords();
    }
  }

  /// 清空所有记录
  Future<void> _clearAllRecords() async {
    final confirmed = await _showClearAllConfirmDialog();

    if (confirmed == true) {
      await _service.clearAllRecords();
      _loadRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: _buildBody(),
    );
  }

  /// 构建主体内容
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_records.isEmpty) {
      return const EmptyRecordsState();
    }

    return RefreshIndicator(
      onRefresh: _loadRecords,
      child: CustomScrollView(
        slivers: [
          // 统计信息卡片
          if (_statistics != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: StatisticsCard(statistics: _statistics!),
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
                  child: RecordCard(
                    record: record,
                    onLongPress: () => _deleteRecord(record.id),
                  ),
                );
              }, childCount: _records.length),
            ),
          ),

          // 底部间距
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  /// 显示删除确认对话框
  Future<bool?> _showDeleteConfirmDialog() {
    return showDialog<bool>(
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
  }

  /// 显示清空所有记录确认对话框
  Future<bool?> _showClearAllConfirmDialog() {
    return showDialog<bool>(
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
  }

  /// 显示错误提示
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
