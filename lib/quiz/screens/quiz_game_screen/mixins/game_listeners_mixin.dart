import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/quiz_room_model.dart';
import '../../../services/quiz_host_service.dart';
import '../../../services/quiz_client_service.dart';
import '../../../providers/quiz_game_provider.dart';

/// 游戏监听器 Mixin
/// 负责设置和管理房间更新、断开连接等事件监听
mixin GameListenersMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  QuizHostService? get hostService;
  QuizClientService? get clientService;
  bool get isHost;
  String get myPlayerId;

  StreamSubscription<QuizRoom>? roomSubscription;
  StreamSubscription? disconnectSubscription;

  void setupGameListeners({required VoidCallback onNavigateToResult}) {
    if (isHost) {
      _setupHostListeners(onNavigateToResult);
    } else {
      _setupClientListeners(onNavigateToResult);
    }
  }

  void _setupHostListeners(VoidCallback onNavigateToResult) {
    // 初始化Provider状态
    final initialRoom = hostService!.gameController.room;
    Future.microtask(() {
      if (mounted) {
        final hostPlayer = initialRoom.players.firstWhere(
          (p) => p.id == 'host',
          orElse: () => initialRoom.players.first,
        );
        ref
            .read(quizGameProvider.notifier)
            .updateRoom(initialRoom, myPlayer: hostPlayer);
      }
    });

    roomSubscription = hostService!.gameController.roomUpdates.listen((room) {
      if (mounted) {
        // 获取房主的题目索引
        final hostPlayer = room.players.firstWhere(
          (p) => p.id == 'host',
          orElse: () => room.players.first,
        );

        // 更新Provider状态，传入玩家的题目索引
        ref
            .read(quizGameProvider.notifier)
            .updateRoom(room, myPlayer: hostPlayer);

        // 检查是否需要导航到结果页
        final gameState = ref.read(quizGameProvider);
        if (room.status == RoomStatus.finished &&
            !gameState.hasNavigatedToResult) {
          onNavigateToResult();
        }
      }
    });

    // 监听断开连接事件
    disconnectSubscription = hostService!.onClientDisconnected.listen((
      playerName,
    ) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('玩家 $playerName 已断开连接'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });
  }

  void _setupClientListeners(VoidCallback onNavigateToResult) {
    // 客户端逻辑
    final initialRoom = clientService!.currentRoom;
    if (initialRoom != null) {
      Future.microtask(() {
        if (mounted) {
          final myPlayerId = clientService!.myPlayerId;
          final myPlayer = initialRoom.players.firstWhere(
            (p) => p.id == myPlayerId,
            orElse: () => initialRoom.players.first,
          );
          ref
              .read(quizGameProvider.notifier)
              .updateRoom(initialRoom, myPlayer: myPlayer);
        }
      });
    }

    roomSubscription = clientService!.roomUpdates.listen((room) {
      if (mounted) {
        // 获取客户端玩家的题目索引
        final myPlayerId = clientService!.myPlayerId;
        final myPlayer = room.players.firstWhere(
          (p) => p.id == myPlayerId,
          orElse: () => room.players.first,
        );

        // 更新Provider状态，传入玩家的题目索引
        ref
            .read(quizGameProvider.notifier)
            .updateRoom(room, myPlayer: myPlayer);

        final gameState = ref.read(quizGameProvider);
        if (room.status == RoomStatus.finished &&
            !gameState.hasNavigatedToResult) {
          onNavigateToResult();
        }
      }
    });

    // 监听断开连接
    disconnectSubscription = clientService!.onDisconnected.listen((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('与主机断开连接'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    });
  }

  void disposeGameListeners() {
    roomSubscription?.cancel();
    disconnectSubscription?.cancel();
  }
}
