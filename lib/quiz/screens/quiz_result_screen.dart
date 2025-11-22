import 'dart:async';
import 'package:flutter/material.dart';
import '../models/quiz_room_model.dart';
import '../models/player_model.dart';
import '../models/game_record_model.dart';
import '../services/quiz_host_service.dart';
import '../services/quiz_client_service.dart';
import '../services/quiz_record_service.dart';
import 'quiz_host_screen/quiz_host_screen.dart';
import 'quiz_client_screen.dart';
import 'quiz_result_screen/widgets/winners_section.dart';
import 'quiz_result_screen/widgets/rank_list_item.dart';
import 'quiz_result_screen/widgets/result_action_buttons.dart';

/// 结果页面
class QuizResultScreen extends StatefulWidget {
  final QuizRoom room;
  final bool isHost;
  final QuizHostService? hostService;
  final QuizClientService? clientService;

  const QuizResultScreen({
    super.key,
    required this.room,
    this.isHost = false,
    this.hostService,
    this.clientService,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  StreamSubscription<QuizRoom>? _roomSubscription;
  final GameRecordService _recordService = GameRecordService();
  bool _hasRecordSaved = false; // 防止重复保存

  @override
  void initState() {
    super.initState();
    _setupListener();
    _saveGameRecord();
  }

  void _setupListener() {
    if (widget.isHost && widget.hostService != null) {
      _roomSubscription = widget.hostService!.gameController.roomUpdates.listen(
        _handleRoomUpdate,
      );
    } else if (!widget.isHost && widget.clientService != null) {
      _roomSubscription = widget.clientService!.roomUpdates.listen(
        _handleRoomUpdate,
      );
    }
  }

  /// 保存游戏记录（从当前玩家视角，防止重复保存）
  Future<void> _saveGameRecord() async {
    // 防止重复保存
    if (_hasRecordSaved) return;

    try {
      // 确保有足够的玩家信息
      if (widget.room.players.length < 2) return;

      // 获取当前玩家ID
      final myPlayerId = widget.isHost
          ? 'host'
          : (widget.clientService?.myPlayerId ?? '');

      // 获取自己和对手
      final myPlayer = widget.room.players.firstWhere(
        (p) => p.id == myPlayerId,
        orElse: () => widget.room.players.first,
      );
      final opponentPlayer = widget.room.players.firstWhere(
        (p) => p.id != myPlayerId,
        orElse: () => widget.room.players.last,
      );

      // 计算游戏时长
      final durationSeconds = _calculateGameDuration();

      // 确定胜负结果（从当前玩家视角）
      final result = _determineGameResult(myPlayer, opponentPlayer);

      // 创建游戏记录
      final record = GameRecord(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        hostId: myPlayer.id,
        hostName: myPlayer.name,
        clientId: opponentPlayer.id,
        clientName: opponentPlayer.name,
        totalQuestions: widget.room.questions.length,
        hostScore: myPlayer.score,
        clientScore: opponentPlayer.score,
        durationSeconds: durationSeconds,
        result: result,
      );

      // 保存记录
      await _recordService.saveRecord(record);
      _hasRecordSaved = true;
      debugPrint('游戏记录已保存: ${myPlayer.name}(我) vs ${opponentPlayer.name}');
    } catch (e) {
      debugPrint('保存游戏记录失败: $e');
    }
  }

  /// 计算游戏时长
  int _calculateGameDuration() {
    if (widget.room.gameEndTime != null &&
        widget.room.questionStartTime != null) {
      return widget.room.gameEndTime!
          .difference(widget.room.questionStartTime!)
          .inSeconds;
    } else if (widget.room.questionStartTime != null) {
      return DateTime.now()
          .difference(widget.room.questionStartTime!)
          .inSeconds;
    } else {
      // 估算：每题平均30秒
      return widget.room.questions.length * 30;
    }
  }

  /// 确定游戏结果
  GameResult _determineGameResult(QuizPlayer myPlayer, QuizPlayer opponent) {
    if (myPlayer.score > opponent.score) {
      return GameResult.win;
    } else if (myPlayer.score < opponent.score) {
      return GameResult.lose;
    } else {
      return GameResult.draw;
    }
  }

  void _handleRoomUpdate(QuizRoom room) {
    if (!mounted) return;

    // 如果房间状态变为 waiting，说明游戏已重置，跳转回大厅
    if (room.status == RoomStatus.waiting) {
      _navigateToLobby();
    }
  }

  void _navigateToLobby() {
    final playerName = _getPlayerName();

    if (widget.isHost) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizHostScreen(
            playerName: playerName,
            existingService: widget.hostService,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizClientScreen(
            playerName: playerName,
            existingService: widget.clientService,
          ),
        ),
      );
    }
  }

  /// 获取玩家名称
  String _getPlayerName() {
    final myPlayerId = widget.isHost
        ? 'host'
        : (widget.clientService?.myPlayerId ?? '');

    try {
      final myPlayer = widget.room.players.firstWhere(
        (p) => p.id == myPlayerId,
      );
      return myPlayer.name;
    } catch (e) {
      return 'Player';
    }
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 按分数排序
    final sortedPlayers = List<QuizPlayer>.from(widget.room.players);
    sortedPlayers.sort((a, b) => b.score.compareTo(a.score));

    return Scaffold(
      appBar: AppBar(
        title: const Text('游戏结果'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 获奖者区域
            if (sortedPlayers.isNotEmpty)
              WinnersSection(players: sortedPlayers),

            // 分隔线
            Container(
              height: 1,
              color: colorScheme.outlineVariant,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),

            // 排行榜标题
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.leaderboard, color: colorScheme.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '查看错题',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // 排行榜
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sortedPlayers.length,
                itemBuilder: (context, index) {
                  return RankListItem(
                    player: sortedPlayers[index],
                    rank: index + 1,
                    room: widget.room,
                  );
                },
              ),
            ),

            // 按钮区域
            ResultActionButtons(
              isHost: widget.isHost,
              hostService: widget.hostService,
              clientService: widget.clientService,
            ),
          ],
        ),
      ),
    );
  }
}
