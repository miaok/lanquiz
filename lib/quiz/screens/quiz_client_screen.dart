import 'dart:async';
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/quiz_room.dart';
import '../services/quiz_client_service.dart';
import 'quiz_game_screen.dart';

/// 客户端页面（玩家）
class QuizClientScreen extends StatefulWidget {
  final String playerName;

  const QuizClientScreen({super.key, required this.playerName});

  @override
  State<QuizClientScreen> createState() => _QuizClientScreenState();
}

class _QuizClientScreenState extends State<QuizClientScreen> {
  final QuizClientService _clientService = QuizClientService();
  String _status = '正在搜索房间...';
  QuizRoom? _room;
  bool _isConnected = false;
  StreamSubscription<String>? _statusSubscription;
  StreamSubscription<QuizRoom>? _roomSubscription;

  @override
  void initState() {
    super.initState();
    _connectToHost();
  }

  Future<void> _connectToHost() async {
    // 创建玩家
    final player = QuizPlayer(
      id: 'player_${DateTime.now().millisecondsSinceEpoch}',
      name: widget.playerName,
    );

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
          if (room.status == RoomStatus.playing && !_isConnected) {
            _isConnected = true;
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

    // 连接到主机
    final success = await _clientService.discoverAndConnect(player);
    if (!success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('连接失败')));
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _roomSubscription?.cancel();
    // 注意：不要在这里关闭 _clientService，因为游戏页面还需要使用它
    // _clientService 会在游戏页面结束时关闭
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('加入房间'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _room == null ? _buildLoadingView() : _buildWaitingView(),
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

  Widget _buildWaitingView() {
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
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: player.isReady
                              ? Colors.green
                              : Colors.grey,
                          child: Text(
                            player.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
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
                          player.id == _room!.hostId ? '房主' : '玩家',
                        ),
                        trailing: Icon(
                          player.isReady
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: player.isReady ? Colors.green : Colors.grey,
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
          child: ElevatedButton(
            onPressed: _toggleReady,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isReady() ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _isReady() ? '取消准备' : '准备',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '等待房主开始游戏...',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
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
