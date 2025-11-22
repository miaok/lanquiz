import 'dart:async';
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/quiz_room.dart';
import '../services/quiz_client_service.dart';
import 'quiz_game_screen.dart';

/// 客户端页面（玩家）
class QuizClientScreen extends StatefulWidget {
  final String playerName;
  final QuizClientService? existingService;

  const QuizClientScreen({
    super.key,
    required this.playerName,
    this.existingService,
  });

  @override
  State<QuizClientScreen> createState() => _QuizClientScreenState();
}

class _QuizClientScreenState extends State<QuizClientScreen> {
  late QuizClientService _clientService;
  String _status = '正在搜索房间...';
  QuizRoom? _room;
  bool _isNavigating = false;
  StreamSubscription<String>? _statusSubscription;
  StreamSubscription<QuizRoom>? _roomSubscription;

  @override
  void initState() {
    super.initState();
    _connectToHost();
  }

  Future<void> _connectToHost() async {
    if (widget.existingService != null) {
      _clientService = widget.existingService!;
      _room = _clientService.currentRoom;
      _status = '已连接';
      _setupListeners();
      return;
    }

    _clientService = QuizClientService();

    // 创建玩家
    final player = QuizPlayer(
      id: 'player_${DateTime.now().millisecondsSinceEpoch}',
      name: widget.playerName,
    );

    // 连接到主机(会初始化StreamController)
    final success = await _clientService.discoverAndConnect(player);

    // 连接成功后再设置监听器
    if (success) {
      _setupListeners();
      if (mounted) {
        setState(() {
          _status = '已连接';
        });
      }
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('连接失败')));
    }
  }

  void _setupListeners() {
    // 监听状态更新
    _statusSubscription = _clientService.statusUpdates.listen((status) {
      if (mounted) {
        setState(() {
          _status = status;
        });
      }
    });

    // 监听房间更新
    _roomSubscription = _clientService.roomUpdates.listen((room) {
      if (mounted) {
        setState(() {
          _room = room;

          // 如果游戏开始，跳转到游戏页面
          if (room.status == RoomStatus.playing && !_isNavigating) {
            _isNavigating = true;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => QuizGameScreen(
                  isHost: false,
                  clientService: _clientService,
                ),
              ),
            );
          }
        });
      }
    });

    // 监听断开连接
    _clientService.onDisconnected.listen((_) {
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

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _roomSubscription?.cancel();
    // 如果不是通过游戏开始导航离开,则清理服务
    if (!_isNavigating) {
      // print('QuizClientScreen dispose: 清理客户端服务');
      _clientService.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PopScope<bool>(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // 如果已经弹出，直接返回

        // 拦截返回操作,显示确认对话框
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认退出'),
            content: const Text('退出将断开与房间的连接。确定要退出吗?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                child: const Text('确定'),
              ),
            ],
          ),
        );

        if (shouldPop == true) {
          // 用户确认退出,清理服务
          // print('用户确认退出,清理客户端服务');
          await _clientService.dispose();
          // 手动触发返回操作
          if (context.mounted) {
            Navigator.of(context).pop(true);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('加入房间')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _room == null
                ? _buildLoadingView()
                : _buildWaitingView(colorScheme, textTheme),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            _status,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingView(ColorScheme colorScheme, TextTheme textTheme) {
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
                Text(
                  _room!.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('题目数量: ${_room!.questions.length}'),
                Text('玩家数: ${_room!.players.length}/${_room!.maxPlayers}'),
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
                  child: Text(
                    '玩家列表',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: _room!.players.length,
                    itemBuilder: (context, index) {
                      final player = _room!.players[index];
                      final isMe = player.id == _clientService.myPlayerId;

                      // 获取玩家IP地址
                      String ipAddress = '';
                      if (player.id == _room!.hostId) {
                        // 房主显示主机IP
                        ipAddress = _clientService.hostIp ?? '未知';
                      } else if (isMe) {
                        // 当前玩家显示本地IP
                        ipAddress = _clientService.myIp ?? '未知';
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
                          child: Text(player.name[0].toUpperCase()),
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
                          '${player.id == _room!.hostId ? '房主' : '玩家'} · $ipAddress',
                          style: TextStyle(fontSize: 12),
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
            onPressed: _toggleReady,
            style: FilledButton.styleFrom(
              backgroundColor: _isReady()
                  ? colorScheme.secondaryContainer
                  : colorScheme.primary,
            ),
            child: Text(
              _isReady() ? '取消准备' : '准备',
              style: textTheme.titleMedium?.copyWith(
                color: _isReady()
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isReady() {
    if (_room == null || _clientService.myPlayerId == null) return false;
    final myPlayer = _room!.players.firstWhere(
      (p) => p.id == _clientService.myPlayerId,
      orElse: () => QuizPlayer(id: '', name: ''),
    );
    return myPlayer.isReady;
  }

  void _toggleReady() {
    _clientService.playerReady(!_isReady());
  }
}
