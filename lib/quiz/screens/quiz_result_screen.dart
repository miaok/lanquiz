import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lanquiz/quiz/models/question.dart';
import '../models/quiz_room.dart';
import '../models/player.dart';
import '../services/quiz_host_service.dart';
import '../services/quiz_client_service.dart';
import 'quiz_home_screen.dart';
import 'quiz_host_screen.dart';
import 'quiz_client_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _setupListener();
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

  void _handleRoomUpdate(QuizRoom room) {
    if (!mounted) return;

    // 如果房间状态变为 waiting，说明游戏已重置，跳转回大厅
    if (room.status == RoomStatus.waiting) {
      _navigateToLobby();
    }
  }

  void _navigateToLobby() {
    // 获取当前玩家名称
    String playerName = '';
    String myPlayerId = widget.isHost
        ? 'host'
        : (widget.clientService?.myPlayerId ?? '');

    try {
      final myPlayer = widget.room.players.firstWhere(
        (p) => p.id == myPlayerId,
      );
      playerName = myPlayer.name;
    } catch (e) {
      playerName = 'Player';
    }

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
            // 获奖者横向展示区域
            if (sortedPlayers.isNotEmpty) _buildWinnersSection(sortedPlayers),
            
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
                  return _buildRankItem(sortedPlayers[index], index + 1);
                },
              ),
            ),

            // 按钮区域
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 再来一局按钮（仅房主可见）
                  if (widget.isHost) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _restartGame,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '再来一局',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 返回主页按钮
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.tonal(
                      onPressed: () async {
                        // 如果是房主且点击返回主页,应该关闭服务
                        if (widget.isHost) {
                          await widget.hostService?.dispose();
                        } else {
                          await widget.clientService?.dispose();
                        }

                        // 确保widget仍然挂载且context有效
                        if (!mounted || !context.mounted) return;

                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const QuizHomeScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('返回主页', style: TextStyle(fontSize: 18)),
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

  /// 构建获奖者区域（竖向排列，减少占据空间）
  Widget _buildWinnersSection(List<QuizPlayer> players) {
    final winners = players.take(3).toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [          
          // 竖向获奖者卡片（节省空间）
          ...winners.asMap().entries.map((entry) {
            final player = entry.value;
            final rank = entry.key + 1;
            return Padding(
              padding: EdgeInsets.only(
                top: rank == 1 ? 0 : 8, // 第一张卡片不需要上边距
                bottom: rank == winners.length ? 0 : 8, // 最后一张卡片不需要下边距
              ),
              child: _buildWinnerCard(player, rank, isMainWinner: rank == 1),
            );
          }),
        ],
      ),
    );
  }

  /// 构建获奖者卡片（横向布局）
  Widget _buildWinnerCard(QuizPlayer winner, int rank, {required bool isMainWinner}) {
    Color? cardColor;
    Color? accentColor;
    IconData? medalIcon;
    
    if (rank == 1) {
      cardColor = const Color(0xFFFFB74D); // 金色
      accentColor = const Color(0xFFFF8F00);
      medalIcon = Icons.emoji_events;
    } else if (rank == 2) {
      cardColor = const Color(0xFFBDBDBD); // 银色
      accentColor = const Color(0xFF757575);
      medalIcon = Icons.emoji_events;
    } else {
      cardColor = const Color(0xFFBCAAA4); // 铜色
      accentColor = const Color(0xFF6D4C41);
      medalIcon = Icons.emoji_events;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor,
            cardColor.withValues(alpha: 0.8),
          ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  void _restartGame() {
    widget.hostService?.restartGame();
  }

  Widget _buildRankItem(QuizPlayer player, int rank) {
    final colorScheme = Theme.of(context).colorScheme;

    Color? medalColor;
    IconData? medalIcon;
    Color rankColor;

    if (rank == 1) {
      medalColor = const Color(0xFFFFB74D);
      medalIcon = Icons.emoji_events;
      rankColor = const Color(0xFFFF8F00);
    } else if (rank == 2) {
      medalColor = const Color(0xFFBDBDBD);
      medalIcon = Icons.emoji_events;
      rankColor = const Color(0xFF757575);
    } else if (rank == 3) {
      medalColor = const Color(0xFFBCAAA4);
      medalIcon = Icons.emoji_events;
      rankColor = const Color(0xFF6D4C41);
    } else {
      medalColor = colorScheme.primaryContainer;
      rankColor = colorScheme.primary;
    }

    final hasWrongAnswers = player.wrongAnswers.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: rank <= 3 ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          enabled: hasWrongAnswers,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: medalColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: rankColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: medalIcon != null
                  ? Icon(medalIcon, color: Colors.white, size: 24)
                  : Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: rankColor,
                      ),
                    ),
            ),
          ),
          title: Text(
            player.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
              color: colorScheme.onSurface,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: rank <= 3 ? rankColor : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (rank <= 3 ? rankColor : colorScheme.primaryContainer).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${player.score} 分',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: rank <= 3 ? Colors.white : colorScheme.primary,
                  ),
                ),
              ),
              if (hasWrongAnswers) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.expand_more,
                    color: colorScheme.error,
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
          children: [
            if (hasWrongAnswers)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '错题回顾',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.error,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...player.wrongAnswers.map((wrongAnswer) {
                      return _buildWrongAnswerItem(wrongAnswer);
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWrongAnswerItem(Map<String, dynamic> wrongAnswer) {
    final colorScheme = Theme.of(context).colorScheme;

    final questionId = wrongAnswer['questionId'] as String;
    final playerAnswer = wrongAnswer['playerAnswer'];
    final correctAnswer = wrongAnswer['correctAnswer'];

    // 查找题目
    final question = widget.room.questions.firstWhere(
      (q) => q.id == questionId,
      orElse: () => widget.room.questions.first, // Fallback
    );

    String playerAnswerText = _formatAnswer(question, playerAnswer);
    String correctAnswerText = _formatAnswer(question, correctAnswer);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 题型标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTypeColor(question.type),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question.type.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question.question,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('你的答案: ', style: TextStyle(color: colorScheme.outline)),
              Expanded(
                child: Text(
                  playerAnswerText,
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('正确答案: ', style: TextStyle(color: colorScheme.outline)),
              Expanded(
                child: Text(
                  correctAnswerText,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(QuestionType type) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case QuestionType.singleChoice:
        return colorScheme.primary;
      case QuestionType.trueFalse:
        return colorScheme.tertiary;
      case QuestionType.multipleChoice:
        return colorScheme.secondary;
    }
  }

  String _formatAnswer(dynamic question, dynamic answer) {
    if (answer == null) return '未作答';

    try {
      if (answer is int) {
        if (answer >= 0 && answer < question.options.length) {
          return question.options[answer];
        }
      } else if (answer is List) {
        final indices = answer.cast<int>()..sort();
        return indices
            .map(
              (i) => (i >= 0 && i < question.options.length)
                  ? question.options[i]
                  : '?',
            )
            .join(', ');
      }
    } catch (e) {
      return answer.toString();
    }
    return answer.toString();
  }
}
