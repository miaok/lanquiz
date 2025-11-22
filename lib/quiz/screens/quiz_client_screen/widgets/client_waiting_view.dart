import 'package:flutter/material.dart';
import '../../../models/quiz_room_model.dart';
import '../../../models/player_model.dart';

class ClientWaitingView extends StatelessWidget {
  final QuizRoom room;
  final String? myPlayerId;
  final String? hostIp;
  final String? myIp;
  final VoidCallback onToggleReady;

  const ClientWaitingView({
    super.key,
    required this.room,
    required this.myPlayerId,
    required this.hostIp,
    required this.myIp,
    required this.onToggleReady,
  });

  bool get _isReady {
    if (myPlayerId == null) return false;
    final myPlayer = room.players.firstWhere(
      (p) => p.id == myPlayerId,
      orElse: () => QuizPlayer(id: '', name: ''),
    );
    return myPlayer.isReady;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 房间信息
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.name, style: textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('题目数量: ${room.questions.length}'),
                Text('玩家数: ${room.players.length}/${room.maxPlayers}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 玩家列表
        Expanded(
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('玩家列表', style: textTheme.titleLarge),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: room.players.length,
                    itemBuilder: (context, index) {
                      final player = room.players[index];
                      final isMe = player.id == myPlayerId;

                      // 获取玩家IP地址
                      String ipAddress = '';
                      if (player.id == room.hostId) {
                        // 房主显示主机IP
                        ipAddress = hostIp ?? '未知';
                      } else if (isMe) {
                        // 当前玩家显示本地IP
                        ipAddress = myIp ?? '未知';
                      } else {
                        // 其他玩家显示未知（客户端无法获取其他客户端的IP）
                        ipAddress = '未知';
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: player.isReady
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          foregroundColor: player.isReady
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                          child: Text(
                            player.name.isNotEmpty
                                ? player.name[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(
                          player.name + (isMe ? ' (我)' : ''),
                          style: TextStyle(
                            fontWeight: isMe
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '${player.id == room.hostId ? '房主' : '玩家'} · $ipAddress',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Icon(
                          player.isReady
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: player.isReady
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 准备按钮
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: onToggleReady,
            style: FilledButton.styleFrom(
              backgroundColor: _isReady
                  ? colorScheme.secondaryContainer
                  : colorScheme.primary,
            ),
            child: Text(
              _isReady ? '取消准备' : '准备',
              style: textTheme.titleMedium?.copyWith(
                color: _isReady
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
