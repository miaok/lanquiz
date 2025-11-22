import 'dart:async';
import 'package:flutter/material.dart';
import '../models/quiz_room.dart';
import '../models/question.dart';
import '../models/player.dart';
import '../services/quiz_host_service.dart';
import '../services/quiz_client_service.dart';
import 'quiz_result_screen.dart';
import 'quiz_game_screen/widgets/player_score_board.dart';
import 'quiz_game_screen/widgets/question_card.dart';
import 'quiz_game_screen/widgets/option_button.dart';
import 'quiz_game_screen/widgets/confirm_button.dart';
import 'widgets/waiting_screen.dart';
import 'quiz_game_screen/widgets/answer_feedback_overlay.dart';

/// 游戏页面
class QuizGameScreen extends StatefulWidget {
  final bool isHost;
  final QuizHostService? hostService;
  final QuizClientService? clientService;

  const QuizGameScreen({
    super.key,
    required this.isHost,
    this.hostService,
    this.clientService,
  });

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen> {
  QuizRoom? _room;
  int? _selectedAnswer; // 单选题/判断题的选择
  final List<int> _selectedAnswers = []; // 多选题的选择
  StreamSubscription<QuizRoom>? _roomSubscription;
  StreamSubscription? _disconnectSubscription;

  // 反馈弹窗状态
  bool _showFeedback = false;
  bool _isFeedbackCorrect = false;

  // 乱序状态
  int _currentQuestionIndex = -1;
  List<int> _shuffledIndices = [];

  // 防止重复导航到结果页面
  bool _hasNavigatedToResult = false;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    // 初始化乱序状态
    if (_room != null) {
      _updateQuestionState(_room!);
    }
  }

  void _setupListeners() {
    if (widget.isHost) {
      _room = widget.hostService!.gameController.room;
      _roomSubscription = widget.hostService!.gameController.roomUpdates.listen(
        (room) {
          if (mounted) {
            setState(() {
              _updateQuestionState(room);
              _room = room;

              if (room.status == RoomStatus.finished &&
                  !_hasNavigatedToResult) {
                _navigateToResult();
              }
            });
          }
        },
      );
    } else {
      _room = widget.clientService!.currentRoom;
      _roomSubscription = widget.clientService!.roomUpdates.listen((room) {
        if (mounted) {
          setState(() {
            _updateQuestionState(room);
            _room = room;

            if (room.status == RoomStatus.finished && !_hasNavigatedToResult) {
              _navigateToResult();
            }
          });
        }
      });
    }

    // 监听断开连接事件
    if (widget.isHost) {
      _disconnectSubscription = widget.hostService!.onClientDisconnected.listen(
        (playerName) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('玩家 $playerName 已断开连接'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
      );
    } else {
      _disconnectSubscription = widget.clientService!.onDisconnected.listen((
        _,
      ) {
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
  }

  void _updateQuestionState(QuizRoom newRoom) {
    final newPlayer = newRoom.players.firstWhere(
      (p) => p.id == _myPlayerId,
      orElse: () => newRoom.players.first,
    );

    if (newPlayer.currentQuestionIndex != _currentQuestionIndex) {
      _currentQuestionIndex = newPlayer.currentQuestionIndex;
      _selectedAnswer = null;
      _selectedAnswers.clear();
      _showFeedback = false;

      // 生成新的乱序索引
      if (_currentQuestionIndex < newRoom.questions.length) {
        final question = newRoom.questions[_currentQuestionIndex];
        _shuffledIndices = List.generate(question.options.length, (i) => i)
          ..shuffle();
      } else {
        _shuffledIndices = [];
      }
    }
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _disconnectSubscription?.cancel();

    // 注意：不要在这里关闭服务，因为服务需要传递给结果页面以便“再来一局”
    // 服务将在 QuizResultScreen 中点击“返回主页”时关闭

    super.dispose();
  }

  // 获取当前玩家
  String get _myPlayerId {
    if (widget.isHost) {
      return 'host';
    } else {
      return widget.clientService!.myPlayerId ?? '';
    }
  }

  // 根据得分对比生成AppBar标题
  String _getAppBarTitle(QuizPlayer myPlayer) {
    if (_room == null) return '答题中...';

    // 找到对手
    final opponent = _room!.players.firstWhere(
      (p) => p.id != _myPlayerId,
      orElse: () => myPlayer, // 如果没有对手，返回自己
    );

    // 如果没有对手，只显示题目进度
    if (opponent.id == myPlayer.id) {
      return '自由练习';
    }

    // 计算得分占比
    final total = myPlayer.score + opponent.score;
    final myRatio = total > 0 ? myPlayer.score / total : 0.5;

    // 根据占比生成状态文本
    String statusText;
    if (myRatio >= 0.7) {
      statusText = '遥遥领先';
    } else if (myRatio >= 0.6) {
      statusText = '稳稳领先';
    } else if (myRatio > 0.5) {
      statusText = '略有优势';
    } else if (myRatio == 0.5) {
      statusText = '棋逢对手';
    } else if (myRatio >= 0.4) {
      statusText = '加油加油';
    } else if (myRatio >= 0.3) {
      statusText = '奋起直追';
    } else {
      statusText = '别放弃';
    }

    return statusText;
  }

  @override
  Widget build(BuildContext context) {
    if (_room == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 获取当前玩家
    final myPlayer = _room!.players.firstWhere(
      (p) => p.id == _myPlayerId,
      orElse: () => _room!.players.first,
    );

    // 如果已完成所有题目，显示等待界面
    if (myPlayer.isFinished) {
      return WaitingScreen(
        room: _room!,
        myPlayerId: _myPlayerId,
        onShowExitDialog: _showExitConfirmDialog,
      );
    }

    // 获取当前题目
    if (myPlayer.currentQuestionIndex >= _room!.questions.length) {
      return const Scaffold(body: Center(child: Text('题目索引超出范围')));
    }

    final question = _room!.questions[myPlayer.currentQuestionIndex];

    return PopScope(
      canPop: false, // 禁止返回
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // 显示确认对话框
          _showExitConfirmDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _getAppBarTitle(myPlayer),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          automaticallyImplyLeading: false,
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // 得分榜
                  PlayerScoreBoard(
                    players: _room!.players,
                    myPlayerId: _myPlayerId,
                    hostId: _room!.hostId,
                    roomStatus: _room!.status,
                    totalQuestions: _room!.questions.length,
                  ),
                  // 题目区域
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 题目
                          QuestionCard(
                            questionText: question.question,
                            questionType: question.type,
                          ),
                          const SizedBox(height: 16),

                          // 选项 (使用乱序索引)
                          ..._shuffledIndices.map((originalIndex) {
                            return OptionButton(
                              question: question,
                              index: originalIndex,
                              hasAnswered: myPlayer.currentAnswer != null,
                              selectedAnswer: _selectedAnswer,
                              selectedAnswers: _selectedAnswers,
                              onSelectSingle: () =>
                                  _selectSingleAnswer(originalIndex, question),
                              onToggleMultiple: () =>
                                  _toggleMultipleChoice(originalIndex),
                            );
                          }),

                          // 多选题确认按钮
                          if (question.type == QuestionType.multipleChoice &&
                              myPlayer.currentAnswer == null) ...[
                            const SizedBox(height: 24),
                            ConfirmButton(
                              selectedCount: _selectedAnswers.length,
                              totalCount: question.options.length,
                              onConfirm: () => _confirmMultipleChoice(question),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 反馈弹窗
            if (_showFeedback)
              AnswerFeedbackOverlay(
                isCorrect: _isFeedbackCorrect,
                isVisible: _showFeedback,
              ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('退出对局', style: Theme.of(context).textTheme.titleLarge),
        content: Text(
          '确定要退出对局吗?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              // 在异步操作前保存 navigator 引用
              final navigator = Navigator.of(context);
              navigator.pop(); // 关闭对话框

              // 清理服务资源
              if (widget.isHost) {
                await widget.hostService?.dispose();
              } else {
                await widget.clientService?.dispose();
              }

              // 返回主页 - 使用保存的 navigator 引用
              if (mounted) {
                navigator.popUntil((route) => route.isFirst);
              }
            },
            child: Text(
              '退出',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 单选题/判断题选择
  void _selectSingleAnswer(int index, Question question) {
    // 如果正在显示反馈，忽略点击
    if (_showFeedback) return;

    setState(() {
      _selectedAnswer = index;
      _showFeedback = true;
      _isFeedbackCorrect = question.isAnswerCorrect(index);
    });

    // 延迟 200ms 后提交答案
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      if (widget.isHost) {
        widget.hostService!.gameController.submitAnswer('host', index);
      } else {
        widget.clientService!.submitAnswer(index);
      }
    });
  }

  // 多选题切换选项
  void _toggleMultipleChoice(int index) {
    if (_showFeedback) return;

    setState(() {
      if (_selectedAnswers.contains(index)) {
        _selectedAnswers.remove(index);
      } else {
        _selectedAnswers.add(index);
      }
    });
  }

  // 多选题确认答案
  void _confirmMultipleChoice(Question question) {
    if (_selectedAnswers.isEmpty || _showFeedback) return;

    // 排序
    final sortedAnswers = List<int>.from(_selectedAnswers)..sort();

    setState(() {
      _showFeedback = true;
      _isFeedbackCorrect = question.isAnswerCorrect(sortedAnswers);
    });

    // 延迟 200ms 后提交答案
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      if (widget.isHost) {
        widget.hostService!.gameController.submitAnswer('host', sortedAnswers);
      } else {
        widget.clientService!.submitAnswer(sortedAnswers);
      }
    });
  }

  void _navigateToResult() {
    // 防止重复导航
    if (_hasNavigatedToResult) return;
    _hasNavigatedToResult = true;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          room: _room!,
          isHost: widget.isHost,
          hostService: widget.hostService,
          clientService: widget.clientService,
        ),
      ),
    );
  }
}
