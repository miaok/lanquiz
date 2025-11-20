import 'dart:async';
import 'package:flutter/material.dart';
import '../models/quiz_room.dart';
import '../models/player.dart';
import '../services/quiz_host_service.dart';
import '../data/question_repository.dart';
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

// 快捷设置模式枚举
enum QuizPresetMode {
  casual, // 娱乐模式
  standard, // 标准模式
  extreme, // 极限模式
}

class _QuizHostScreenState extends State<QuizHostScreen> {
  late QuizHostService _hostService;
  QuizRoom? _room;
  bool _isInitialized = false;
  StreamSubscription<QuizRoom>? _roomUpdateSubscription;

  // 题型数量设置
  int _trueFalseCount = 10; // 判断题数量，默认1道
  int _singleChoiceCount = 10; // 单选题数量，默认1道
  int _multipleChoiceCount = 10; // 多选题数量，默认1道

  // 当前选中的预设模式
  QuizPresetMode? _selectedPreset = QuizPresetMode.casual;

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
    _hostService.updateQuestionConfig(
      trueFalseCount: _trueFalseCount,
      singleChoiceCount: _singleChoiceCount,
      multipleChoiceCount: _multipleChoiceCount,
    );

    // 创建房间 - 使用配置的题型数量
    final room = QuizRoom(
      id: 'room_${DateTime.now().millisecondsSinceEpoch}',
      name: '${widget.playerName}的房间',
      hostId: 'host',
      maxPlayers: 2,
      questions: QuestionRepository.getQuestionsByConfig(
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

    // 监听客户端断开连接
    _hostService.onClientDisconnected.listen((playerName) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('玩家 $playerName 已断开连接'),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _roomUpdateSubscription?.cancel();
    // 如果不是通过 _startGame 导航离开,则清理服务
    // 通过检查是否还有其他路由来判断
    if (!_isNavigatingToGame) {
      print('QuizHostScreen dispose: 清理主机服务');
      _hostService.dispose();
    }
    super.dispose();
  }

  bool _isNavigatingToGame = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (!_isInitialized || _room == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope<bool>(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // 如果已经弹出，直接返回

        // 拦截返回操作,显示确认对话框
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认退出'),
            content: const Text('退出将关闭房间,所有玩家将被断开连接。确定要退出吗?'),
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
          print('用户确认退出,清理主机服务');
          await _hostService.dispose();
          // 手动触发返回操作
          if (context.mounted) {
            Navigator.of(context).pop(true);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_room!.name)),
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
                          context: context,
                          label: '判断题',
                          count: _trueFalseCount,
                          onChanged: (value) {
                            setState(() {
                              _trueFalseCount = value;
                              _selectedPreset = null; // 手动调整时清除预设
                            });
                            _updateRoomQuestions();
                          },
                          icon: Icons.check_circle_outline,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        // 单选题数量
                        _buildQuestionCountSetting(
                          context: context,
                          label: '单选题',
                          count: _singleChoiceCount,
                          onChanged: (value) {
                            setState(() {
                              _singleChoiceCount = value;
                              _selectedPreset = null; // 手动调整时清除预设
                            });
                            _updateRoomQuestions();
                          },
                          icon: Icons.radio_button_checked,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(height: 12),
                        // 多选题数量
                        _buildQuestionCountSetting(
                          context: context,
                          label: '多选题',
                          count: _multipleChoiceCount,
                          onChanged: (value) {
                            setState(() {
                              _multipleChoiceCount = value;
                              _selectedPreset = null; // 手动调整时清除预设
                            });
                            _updateRoomQuestions();
                          },
                          icon: Icons.checklist,
                          color: colorScheme.tertiary,
                        ),
                        const SizedBox(height: 12),
                        // 快捷设置按钮
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: SegmentedButton<QuizPresetMode>(
                                segments: const [
                                  ButtonSegment<QuizPresetMode>(
                                    value: QuizPresetMode.casual,
                                    label: Text('娱乐'),
                                    icon: Icon(
                                      Icons.sentiment_satisfied_alt,
                                      size: 18,
                                    ),
                                  ),
                                  ButtonSegment<QuizPresetMode>(
                                    value: QuizPresetMode.standard,
                                    label: Text('标准'),
                                    icon: Icon(Icons.star, size: 18),
                                  ),
                                  ButtonSegment<QuizPresetMode>(
                                    value: QuizPresetMode.extreme,
                                    label: Text('极限'),
                                    icon: Icon(
                                      Icons.local_fire_department,
                                      size: 18,
                                    ),
                                  ),
                                ],
                                selected: _selectedPreset != null
                                    ? {_selectedPreset!}
                                    : {},
                                emptySelectionAllowed: true, // 允许空选择
                                onSelectionChanged:
                                    (Set<QuizPresetMode> selected) {
                                      if (selected.isNotEmpty) {
                                        _applyPresetMode(selected.first);
                                      }
                                    },
                                style: ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                                  player.id == 'host' ? '房主' : '玩家',
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

                // 开始游戏按钮
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _room!.allPlayersReady ? _startGame : null,
                    child: Text(
                      _room!.allPlayersReady
                          ? '开始游戏'
                          : '等待所有玩家准备 (${_room!.players.where((p) => p.isReady).length}/${_room!.players.length})',
                      style: textTheme.titleMedium?.copyWith(
                        color: _room!.allPlayersReady
                            ? colorScheme.onPrimary
                            : null, // disabled 状态使用默认颜色
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startGame() {
    _isNavigatingToGame = true;
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

    final newQuestions = QuestionRepository.getQuestionsByConfig(
      trueFalseCount: _trueFalseCount,
      singleChoiceCount: _singleChoiceCount,
      multipleChoiceCount: _multipleChoiceCount,
    );

    // 更新 Service 中的配置
    _hostService.updateQuestionConfig(
      trueFalseCount: _trueFalseCount,
      singleChoiceCount: _singleChoiceCount,
      multipleChoiceCount: _multipleChoiceCount,
    );

    // 通过游戏控制器更新题目
    _hostService.gameController.updateQuestions(newQuestions);
  }

  /// 应用预设模式
  void _applyPresetMode(QuizPresetMode mode) {
    setState(() {
      _selectedPreset = mode;
      switch (mode) {
        case QuizPresetMode.casual:
          // 娱乐模式: 各10题
          _trueFalseCount = 10;
          _singleChoiceCount = 10;
          _multipleChoiceCount = 10;
          break;
        case QuizPresetMode.standard:
          // 标准模式: 判断34、单选和多选33
          _trueFalseCount = 34;
          _singleChoiceCount = 33;
          _multipleChoiceCount = 33;
          break;
        case QuizPresetMode.extreme:
          // 极限模式: 判断68、单选和多选66
          _trueFalseCount = 68;
          _singleChoiceCount = 66;
          _multipleChoiceCount = 66;
          break;
      }
    });
    _updateRoomQuestions();
  }

  /// 构建题型数量设置控件
  Widget _buildQuestionCountSetting({
    required BuildContext context,
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
              max: 100,
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
