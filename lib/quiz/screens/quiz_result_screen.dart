import 'package:flutter/material.dart';
import '../models/quiz_room.dart';
import '../models/player.dart';
import 'quiz_home_screen.dart';

/// 结果页面
class QuizResultScreen extends StatelessWidget {
  final QuizRoom room;

  const QuizResultScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    // 按分数排序
    final sortedPlayers = List<QuizPlayer>.from(room.players);
    sortedPlayers.sort((a, b) => b.score.compareTo(a.score));

    return Scaffold(
      appBar: AppBar(
        title: const Text('游戏结果'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 冠军展示
            if (sortedPlayers.isNotEmpty) _buildWinnerCard(sortedPlayers[0]),

            // 排行榜
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedPlayers.length,
                itemBuilder: (context, index) {
                  return _buildRankItem(sortedPlayers[index], index + 1);
                },
              ),
            ),

            // 返回按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const QuizHomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('返回主页', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinnerCard(QuizPlayer winner) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber[700]!, Colors.amber[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 32, color: Colors.white),
          const SizedBox(height: 12),
          const Text(
            '冠军',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            winner.name,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${winner.score} 分',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankItem(QuizPlayer player, int rank) {
    Color? medalColor;
    IconData? medalIcon;

    if (rank == 1) {
      medalColor = Colors.amber[700];
      medalIcon = Icons.emoji_events;
    } else if (rank == 2) {
      medalColor = Colors.grey[400];
      medalIcon = Icons.emoji_events;
    } else if (rank == 3) {
      medalColor = Colors.brown[400];
      medalIcon = Icons.emoji_events;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: rank <= 3 ? 4 : 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: medalColor ?? Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: medalIcon != null
                ? Icon(medalIcon, color: Colors.white, size: 28)
                : Text(
                    '$rank',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        title: Text(
          player.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue[700],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${player.score} 分',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
