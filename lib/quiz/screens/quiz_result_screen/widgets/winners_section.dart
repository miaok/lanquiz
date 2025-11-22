import 'package:flutter/material.dart';
import '../../../models/player_model.dart';
import 'winner_card.dart';

/// 获奖者区域组件
class WinnersSection extends StatelessWidget {
  final List<QuizPlayer> players;

  const WinnersSection({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
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
              child: WinnerCard(
                winner: player,
                rank: rank,
                isMainWinner: rank == 1,
              ),
            );
          }),
        ],
      ),
    );
  }
}
