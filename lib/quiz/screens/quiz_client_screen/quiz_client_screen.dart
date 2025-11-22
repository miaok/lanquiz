import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/player_model.dart';
import '../../models/quiz_room_model.dart';
import '../../services/quiz_client_service.dart';
import '../quiz_game_screen/quiz_game_screen.dart';
import 'widgets/client_loading_view.dart';
import 'widgets/client_waiting_view.dart';
import '../../utils/app_logger.dart';

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
      appLogger.d('QuizClientScreen dispose: 清理客户端服务');
      _clientService.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
          appLogger.d('用户确认退出,清理客户端服务');
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
                ? ClientLoadingView(status: _status)
                : ClientWaitingView(
                    room: _room!,
                    myPlayerId: _clientService.myPlayerId,
                    hostIp: _clientService.hostIp,
                    myIp: _clientService.myIp,
                    onToggleReady: _toggleReady,
                  ),
          ),
        ),
      ),
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
