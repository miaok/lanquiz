import 'dart:async';
import 'package:flutter/material.dart';
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
    // 按分数排序
    final sortedPlayers = List<QuizPlayer>.from(widget.room.players);
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
                      child: ElevatedButton(
                        onPressed: _restartGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
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
                    child: ElevatedButton(
                      onPressed: () {
                        // 如果是房主且点击返回主页，应该关闭服务
                        if (widget.isHost) {
                          widget.hostService?.dispose();
                        } else {
                          widget.clientService?.dispose();
                        }

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
                ],
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
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 32, color: Colors.white),
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
