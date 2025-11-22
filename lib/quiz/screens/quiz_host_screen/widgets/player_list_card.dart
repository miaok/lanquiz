import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/quiz_room_model.dart';
import '../../../models/player_model.dart';
import '../../../services/quiz_host_service.dart';

/// 玩家列表卡片组件
class PlayerListCard extends StatelessWidget {
  final QuizRoom room;
  final QuizHostService hostService;

  const PlayerListCard({
    super.key,
    required this.room,
    required this.hostService,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('玩家列表', style: Theme.of(context).textTheme.titleLarge),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: room.players.length,
              itemBuilder: (context, index) {
                final player = room.players[index];
                final ipAddress = _getPlayerIpAddress(player);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: player.isReady
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    foregroundColor: player.isReady
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                    child: Text(player.name[0].toUpperCase()),
                  ),
                  title: Text(player.name),
                  subtitle: Text(
                    '${player.id == 'host' ? '房主' : '玩家'} · $ipAddress',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Icon(
                    player.isReady ? Icons.check_circle : Icons.circle_outlined,
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
    );
  }

  /// 获取玩家IP地址
  String _getPlayerIpAddress(QuizPlayer player) {
    if (player.id == 'host') {
      return hostService.hostIp ?? '未知';
    } else {
      // 查找对应的客户端Socket
      Socket? clientSocket;
      for (final socket in hostService.clients) {
        if (hostService.clientPlayerIds[socket] == player.id) {
          clientSocket = socket;
          break;
        }
      }
      if (clientSocket != null) {
        return clientSocket.remoteAddress.address;
      } else {
        return '未知';
      }
    }
  }
}
