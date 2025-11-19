import 'dart:async';
import 'package:flutter/material.dart';
import '../models/quiz_room.dart';
import '../models/player.dart';
import '../services/quiz_host_service.dart';
import '../data/sample_questions.dart';
import 'quiz_game_screen.dart';

/// 房主页面
class QuizHostScreen extends StatefulWidget {
  final String playerName;
  final QuizHostService? existingService;

  const QuizHostScreen({
    super.key,
    required this.playerName,
    this.existingService,
  });

  @override
  State<QuizHostScreen> createState() => _QuizHostScreenState();
}

class _QuizHostScreenState extends State<QuizHostScreen> {
  late QuizHostService _hostService;
  QuizRoom? _room;
  bool _isInitialized = false;
  StreamSubscription<QuizRoom>? _roomUpdateSubscription;

  // 题型数量设置
  int _trueFalseCount = 1; // 判断题数量，默认1道
  int _singleChoiceCount = 1; // 单选题数量，默认1道
  int _multipleChoiceCount = 1; // 多选题数量，默认1道

  @override
  void initState() {
    super.initState();
    _initializeHost();
  }

  Future<void> _initializeHost() async {
    if (widget.existingService != null) {
      _hostService = widget.existingService!;
      _room = _hostService.gameController.room;
      _isInitialized = true;
      _setupRoomListener();
      return;
    }

    _hostService = QuizHostService();

    // 创建房间 - 使用配置的题型数量
    final room = QuizRoom(
      id: 'room_${DateTime.now().millisecondsSinceEpoch}',
      name: '${widget.playerName}的房间',
      hostId: 'host',
      maxPlayers: 2,
      questions: SampleQuestions.getQuestionsByConfig(
        trueFalseCount: _trueFalseCount,
        singleChoiceCount: _singleChoiceCount,
        multipleChoiceCount: _multipleChoiceCount,
      ),
    );

    // 添加房主作为玩家
    room.players.add(
      QuizPlayer(
        id: 'host',
        name: widget.playerName,
        isReady: true, // 房主默认准备
      ),
    );

    final success = await _hostService.initialize(room);
    if (success) {
      if (!mounted) return;
      setState(() {
        _room = _hostService.gameController.room;
        _isInitialized = true;
      });

      _setupRoomListener();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('创建房间失败')));
        Navigator.pop(context);
      }
    }
  }

  void _setupRoomListener() {
    _roomUpdateSubscription = _hostService.gameController.roomUpdates.listen((
      updatedRoom,
    ) {
      if (mounted) {
        setState(() {
          _room = updatedRoom;
        });
      }
    });
  }

  @override
  void dispose() {
    _roomUpdateSubscription?.cancel();
    // 注意：不要在这里关闭 _hostService，因为游戏页面还需要使用它
    // _hostService 会在游戏页面结束时关闭
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _room == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_room!.name),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 题目设置
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 判断题数量
                      _buildQuestionCountSetting(
                        label: '判断题',
                        count: _trueFalseCount,
                        onChanged: (value) {
                          setState(() {
                            _trueFalseCount = value;
                          });
                          _updateRoomQuestions();
                        },
                        icon: Icons.check_circle_outline,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      // 单选题数量
                      _buildQuestionCountSetting(
                        label: '单选题',
                        count: _singleChoiceCount,
                        onChanged: (value) {
                          setState(() {
                            _singleChoiceCount = value;
                          });
                          _updateRoomQuestions();
                        },
                        icon: Icons.radio_button_checked,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      // 多选题数量
                      _buildQuestionCountSetting(
                        label: '多选题',
                        count: _multipleChoiceCount,
                        onChanged: (value) {
                          setState(() {
                            _multipleChoiceCount = value;
                          });
                          _updateRoomQuestions();
                        },
                        icon: Icons.checklist,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      // 总题数显示
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.purple.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.quiz,
                                  color: Colors.purple[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '总题数',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple[700],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${_trueFalseCount + _singleChoiceCount + _multipleChoiceCount} ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 房间信息
              // Card(
              //   child: Padding(
              //     padding: const EdgeInsets.all(16),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Text(
              //           '房间信息',
              //           style: Theme.of(context).textTheme.titleLarge,
              //         ),
              //         const SizedBox(height: 8),
              //         Text('题目数量: ${_room!.questions.length}'),
              //         Text('最大玩家数: ${_room!.maxPlayers}'),
              //         Text('当前玩家数: ${_room!.players.length}'),
              //       ],
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 16),

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
                              title: Text(player.name),
                              subtitle: Text(player.id == 'host' ? '房主' : '玩家'),
                              trailing: Icon(
                                player.isReady
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: player.isReady
                                    ? Colors.green
                                    : Colors.grey,
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

              // 开始游戏按钮
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _room!.allPlayersReady ? _startGame : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _room!.allPlayersReady
                        ? '开始游戏'
                        : '等待所有玩家准备 (${_room!.players.where((p) => p.isReady).length}/${_room!.players.length})',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startGame() {
    _hostService.startGame();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QuizGameScreen(isHost: true, hostService: _hostService),
      ),
    );
  }

  /// 更新房间的题目列表
  void _updateRoomQuestions() {
    if (_room == null || !_isInitialized) return;

    final newQuestions = SampleQuestions.getQuestionsByConfig(
      trueFalseCount: _trueFalseCount,
      singleChoiceCount: _singleChoiceCount,
      multipleChoiceCount: _multipleChoiceCount,
    );

    // 通过游戏控制器更新题目
    _hostService.gameController.updateQuestions(newQuestions);
  }

  /// 构建题型数量设置控件
  Widget _buildQuestionCountSetting({
    required String label,
    required int count,
    required ValueChanged<int> onChanged,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Slider(
              value: count.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              activeColor: color,
              inactiveColor: color.withValues(alpha: 0.3),
              onChanged: (value) {
                onChanged(value.round());
              },
            ),
          ),
          Container(
            width: 28,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}