import 'package:flutter/material.dart';
import '../../../models/quiz_room_model.dart';
import '../../../utils/haptic_feedback.dart';

/// 开始游戏按钮组件
class StartGameButton extends StatelessWidget {
  final QuizRoom room;
  final VoidCallback onStartGame;

  const StartGameButton({
    super.key,
    required this.room,
    required this.onStartGame,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final canStart = room.allPlayersReady;

    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: canStart
            ? () {
                HapticFeedback.heavy();
                onStartGame();
              }
            : null,
        child: Text(
          canStart
              ? '开始游戏'
              : '等待所有玩家准备 (${room.players.where((p) => p.isReady).length}/${room.players.length})',
          style: textTheme.titleMedium?.copyWith(
            color: canStart ? colorScheme.onPrimary : null,
          ),
        ),
      ),
    );
  }
}
