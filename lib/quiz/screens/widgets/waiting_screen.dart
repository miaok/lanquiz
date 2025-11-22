import 'package:flutter/material.dart';
import '../../models/quiz_room.dart';
import '../quiz_game_screen/widgets/player_score_board.dart';

/// 等待其他玩家完成的界面组件
class WaitingScreen extends StatelessWidget {
  final QuizRoom room;
  final String myPlayerId;
  final VoidCallback onShowExitDialog;

  const WaitingScreen({
    super.key,
    required this.room,
    required this.myPlayerId,
    required this.onShowExitDialog,
  });

  @override
  Widget build(BuildContext context) {
    final finishedCount = room.players.where((p) => p.isFinished).length;
    final totalCount = room.players.length;
    final unfinishedPlayers = room.players.where((p) => !p.isFinished).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          onShowExitDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('等待其他玩家', style: Theme.of(context).textTheme.titleLarge),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // 得分榜
              PlayerScoreBoard(
                players: room.players,
                myPlayerId: myPlayerId,
                hostId: room.hostId,
                roomStatus: room.status,
                totalQuestions: room.questions.length,
              ),

              // 等待内容
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 100,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '你已完成所有题目！',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '等待其他玩家完成答题...',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 32),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircularProgressIndicator(),
                                    const SizedBox(width: 16),
                                    Text(
                                      '$finishedCount / $totalCount 人已完成',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (unfinishedPlayers.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  const Text(
                                    '未完成的玩家：',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...unfinishedPlayers.map(
                                    (player) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.person,
                                            size: 16,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            player.name,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.labelLarge,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '第 ${player.currentQuestionIndex + 1} 题',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
