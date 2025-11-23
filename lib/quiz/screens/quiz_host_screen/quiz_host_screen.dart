import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/quiz_room_model.dart';
import '../../models/player_model.dart';
import '../../services/quiz_host_service.dart';
import '../../data/question_repository.dart';
import '../quiz_game_screen/quiz_game_screen.dart';
import 'widgets/question_config_card.dart';
import 'widgets/player_list_card.dart';
import 'widgets/start_game_button.dart';
import 'widgets/preset_mode_selector.dart';
import 'widgets/game_mode_selector.dart';

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
  int _trueFalseCount = 34;
  int _singleChoiceCount = 33;
  int _multipleChoiceCount = 33;

  // 当前选中的预设模式
  QuizPresetMode? _selectedPreset = QuizPresetMode.standard;

  // 游戏模式
  GameMode _selectedGameMode = GameMode.fast;

  // 导航标志
  bool _isNavigatingToGame = false;

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

    // 创建房间
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
      gameMode: _selectedGameMode,
    );

    // 添加房主作为玩家
    room.players.add(
      QuizPlayer(id: 'host', name: widget.playerName, isReady: true),
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
        _showErrorAndExit('创建房间失败，请确保已连接WiFi局域网');
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
    if (!_isNavigatingToGame) {
      _hostService.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _room == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope<bool>(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _showExitConfirmDialog();
        if (shouldPop == true) {
          await _hostService.dispose();
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
                // 题目配置卡片
                QuestionConfigCard(
                  trueFalseCount: _trueFalseCount,
                  singleChoiceCount: _singleChoiceCount,
                  multipleChoiceCount: _multipleChoiceCount,
                  selectedPreset: _selectedPreset,
                  onTrueFalseChanged: (value) =>
                      _handleQuestionCountChange(trueFalse: value),
                  onSingleChoiceChanged: (value) =>
                      _handleQuestionCountChange(singleChoice: value),
                  onMultipleChoiceChanged: (value) =>
                      _handleQuestionCountChange(multipleChoice: value),
                  onPresetChanged: _applyPresetMode,
                ),

                // 游戏模式选择
                GameModeSelector(
                  selectedMode: _selectedGameMode,
                  onModeChanged: _handleGameModeChange,
                ),

                // 玩家列表
                Expanded(
                  child: PlayerListCard(
                    room: _room!,
                    hostService: _hostService,
                  ),
                ),
                const SizedBox(height: 16),

                // 开始游戏按钮
                StartGameButton(room: _room!, onStartGame: _startGame),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 处理题目数量变化
  void _handleQuestionCountChange({
    int? trueFalse,
    int? singleChoice,
    int? multipleChoice,
  }) {
    setState(() {
      if (trueFalse != null) _trueFalseCount = trueFalse;
      if (singleChoice != null) _singleChoiceCount = singleChoice;
      if (multipleChoice != null) _multipleChoiceCount = multipleChoice;
      _selectedPreset = null; // 手动调整时清除预设
    });
    _updateRoomQuestions();
  }

  /// 应用预设模式
  void _applyPresetMode(QuizPresetMode? mode) {
    if (mode == null) return;

    final config = PresetModeConfig.getConfig(mode);
    setState(() {
      _selectedPreset = mode;
      _trueFalseCount = config.trueFalseCount;
      _singleChoiceCount = config.singleChoiceCount;
      _multipleChoiceCount = config.multipleChoiceCount;
    });
    _updateRoomQuestions();
  }

  /// 更新房间的题目列表
  void _updateRoomQuestions() {
    if (_room == null || !_isInitialized) return;

    final newQuestions = QuestionRepository.getQuestionsByConfig(
      trueFalseCount: _trueFalseCount,
      singleChoiceCount: _singleChoiceCount,
      multipleChoiceCount: _multipleChoiceCount,
    );

    _hostService.updateQuestionConfig(
      trueFalseCount: _trueFalseCount,
      singleChoiceCount: _singleChoiceCount,
      multipleChoiceCount: _multipleChoiceCount,
    );

    _hostService.gameController.updateQuestions(newQuestions);
  }

  /// 处理游戏模式变化
  void _handleGameModeChange(GameMode mode) {
    setState(() {
      _selectedGameMode = mode;
    });
    if (_isInitialized) {
      _hostService.gameController.updateGameMode(mode);
    }
  }

  /// 开始游戏
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

  /// 显示退出确认对话框
  Future<bool?> _showExitConfirmDialog() {
    return showDialog<bool>(
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
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示错误并退出
  void _showErrorAndExit(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
    Navigator.pop(context);
  }
}
