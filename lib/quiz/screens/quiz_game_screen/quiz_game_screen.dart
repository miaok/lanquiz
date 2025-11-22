import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/quiz_room_model.dart';
import '../../models/question_model.dart';
import '../../models/player_model.dart';
import '../../services/quiz_host_service.dart';
import '../../services/quiz_client_service.dart';
import '../../providers/quiz_game_provider.dart';
import '../quiz_result_screen/quiz_result_screen.dart';
import 'widgets/player_score_board.dart';
import 'widgets/question_card.dart';
import 'widgets/option_button.dart';
import 'widgets/confirm_button.dart';
import 'widgets/waiting_screen.dart';
import 'widgets/answer_feedback_overlay.dart';

/// 游戏页面
class QuizGameScreen extends ConsumerStatefulWidget {
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
  ConsumerState<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends ConsumerState<QuizGameScreen> {
  // 保留 StreamSubscription（仍需监听Service）
  StreamSubscription<QuizRoom>? _roomSubscription;
  StreamSubscription? _disconnectSubscription;
  Timer? _feedbackTimer;

  // 所有游戏状态现在由 Provider 管理

  @override
  void initState() {
    super.initState();
    // 重置状态，确保每次进入页面都是新的开始
    // 使用 Future.microtask 避免在构建期间修改 Provider
    Future.microtask(() {
      ref.read(quizGameProvider.notifier).reset();
    });
    _setupListeners();
  }

  void _setupListeners() {
    if (widget.isHost) {
      // 初始化Provider状态
      final initialRoom = widget.hostService!.gameController.room;
      Future.microtask(() {
        if (mounted) {
          final hostPlayer = initialRoom.players.firstWhere(
            (p) => p.id == 'host',
            orElse: () => initialRoom.players.first,
          );
          ref
              .read(quizGameProvider.notifier)
              .updateRoom(
                initialRoom,
                playerQuestionIndex: hostPlayer.currentQuestionIndex,
              );
        }
      });

      _roomSubscription = widget.hostService!.gameController.roomUpdates.listen(
        (room) {
          if (mounted) {
            // 获取房主的题目索引
            final hostPlayer = room.players.firstWhere(
              (p) => p.id == 'host',
              orElse: () => room.players.first,
            );

            // 更新Provider状态，传入玩家的题目索引
            ref
                .read(quizGameProvider.notifier)
                .updateRoom(
                  room,
                  playerQuestionIndex: hostPlayer.currentQuestionIndex,
                );

            // 检查是否需要导航到结果页
            final gameState = ref.read(quizGameProvider);
            if (room.status == RoomStatus.finished &&
                !gameState.hasNavigatedToResult) {
              _navigateToResult();
            }
          }
        },
      );
    } else {
      // 客户端逻辑
      final initialRoom = widget.clientService!.currentRoom;
      if (initialRoom != null) {
        Future.microtask(() {
          if (mounted) {
            final myPlayerId = widget.clientService!.myPlayerId;
            final myPlayer = initialRoom.players.firstWhere(
              (p) => p.id == myPlayerId,
              orElse: () => initialRoom.players.first,
            );
            ref
                .read(quizGameProvider.notifier)
                .updateRoom(
                  initialRoom,
                  playerQuestionIndex: myPlayer.currentQuestionIndex,
                );
          }
        });
      }

      _roomSubscription = widget.clientService!.roomUpdates.listen((room) {
        if (mounted) {
          // 获取客户端玩家的题目索引
          final myPlayerId = widget.clientService!.myPlayerId;
          final myPlayer = room.players.firstWhere(
            (p) => p.id == myPlayerId,
            orElse: () => room.players.first,
          );

          // 更新Provider状态，传入玩家的题目索引
          ref
              .read(quizGameProvider.notifier)
              .updateRoom(
                room,
                playerQuestionIndex: myPlayer.currentQuestionIndex,
              );

          final gameState = ref.read(quizGameProvider);
          if (room.status == RoomStatus.finished &&
              !gameState.hasNavigatedToResult) {
            _navigateToResult();
          }
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

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _disconnectSubscription?.cancel();
    _feedbackTimer?.cancel();

    // 重置Provider状态
    // ref.read(quizGameProvider.notifier).reset(); // 移至 initState 防止 dispose 报错

    // 注意：不要在这里关闭服务，因为服务需要传递给结果页面以便"再来一局"
    // 服务将在 QuizResultScreen 中点击"返回主页"时关闭

    super.dispose();
  }

  // 获取当前玩家ID
  String get _myPlayerId {
    if (widget.isHost) {
      return 'host';
    } else {
      return widget.clientService!.myPlayerId ?? '';
    }
  }

  // 根据得分对比生成AppBar标题
  String _getAppBarTitle(QuizPlayer myPlayer, QuizRoom room) {
    // 找到对手
    final opponent = room.players.firstWhere(
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
    // 从Provider读取状态
    final gameState = ref.watch(quizGameProvider);
    final room = gameState.room;

    if (room == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 获取当前玩家
    final myPlayer = room.players.firstWhere(
      (p) => p.id == _myPlayerId,
      orElse: () => room.players.first,
    );

    // 如果已完成所有题目，显示等待界面
    if (myPlayer.isFinished) {
      return WaitingScreen(
        room: room,
        myPlayerId: _myPlayerId,
        onShowExitDialog: _showExitConfirmDialog,
      );
    }

    // 获取当前题目
    if (myPlayer.currentQuestionIndex >= room.questions.length) {
      return const Scaffold(body: Center(child: Text('题目索引超出范围')));
    }

    final question = room.questions[myPlayer.currentQuestionIndex];

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
            _getAppBarTitle(myPlayer, room),
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
                    players: room.players,
                    myPlayerId: _myPlayerId,
                    hostId: room.hostId,
                    roomStatus: room.status,
                    totalQuestions: room.questions.length,
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
                          ...gameState.shuffledIndices.asMap().entries.map((
                            entry,
                          ) {
                            final displayIndex = entry.key;
                            final originalIndex = entry.value;
                            return OptionButton(
                              question: question,
                              index: originalIndex,
                              hasAnswered: myPlayer.currentAnswer != null,
                              selectedAnswer:
                                  gameState.selectedAnswer == displayIndex
                                  ? originalIndex
                                  : null,
                              selectedAnswers: gameState.selectedAnswers
                                  .map((i) => gameState.shuffledIndices[i])
                                  .toList(),
                              onSelectSingle: () =>
                                  _selectSingleAnswer(displayIndex, question),
                              onToggleMultiple: () =>
                                  _toggleMultipleChoice(displayIndex),
                            );
                          }),

                          // 多选题确认按钮
                          if (question.type == QuestionType.multipleChoice &&
                              myPlayer.currentAnswer == null) ...[
                            const SizedBox(height: 24),
                            ConfirmButton(
                              selectedCount: gameState.selectedAnswers.length,
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
            if (gameState.showFeedback)
              AnswerFeedbackOverlay(
                isCorrect: gameState.isFeedbackCorrect,
                isVisible: gameState.showFeedback,
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
  void _selectSingleAnswer(int displayIndex, Question question) {
    final gameState = ref.read(quizGameProvider);

    // 如果正在显示反馈，忽略点击
    if (gameState.showFeedback) return;

    // 获取原始索引
    final originalIndex = gameState.shuffledIndices[displayIndex];

    // 更新Provider状态 - 显示选中效果（会保持到下一题）
    ref.read(quizGameProvider.notifier).selectSingleAnswer(displayIndex);

    // 检查答案是否正确
    final isCorrect = question.isAnswerCorrect(
      SingleChoiceAnswer(originalIndex),
    );

    // 延迟显示反馈，让用户看到选中的高亮效果
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      // 显示反馈
      ref.read(quizGameProvider.notifier).showFeedback(isCorrect);

      // 再延迟后提交答案并隐藏反馈
      _feedbackTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;

        // 隐藏反馈（选中状态会在题目索引变化时自动清除）
        ref.read(quizGameProvider.notifier).hideFeedback();

        // 提交答案到服务（会触发题目索引更新，自动清除选中状态）
        if (widget.isHost) {
          widget.hostService!.gameController.submitAnswer(
            'host',
            originalIndex,
          );
        } else {
          widget.clientService!.submitAnswer(originalIndex);
        }
      });
    });
  }

  // 多选题切换选项
  void _toggleMultipleChoice(int displayIndex) {
    final gameState = ref.read(quizGameProvider);
    if (gameState.showFeedback) return;

    ref.read(quizGameProvider.notifier).toggleMultipleChoice(displayIndex);
  }

  // 多选题确认答案
  void _confirmMultipleChoice(Question question) {
    final gameState = ref.read(quizGameProvider);
    if (gameState.selectedAnswers.isEmpty || gameState.showFeedback) return;

    // 转换为原始索引并排序
    final originalIndices =
        gameState.selectedAnswers
            .map((i) => gameState.shuffledIndices[i])
            .toList()
          ..sort();

    // 检查答案是否正确
    final isCorrect = question.isAnswerCorrect(
      MultipleChoiceAnswer(originalIndices),
    );

    // 延迟显示反馈，让用户看到选中的高亮效果
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      // 显示反馈
      ref.read(quizGameProvider.notifier).showFeedback(isCorrect);

      // 再延迟后提交答案并隐藏反馈
      _feedbackTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;

        // 隐藏反馈（选中状态会在题目索引变化时自动清除）
        ref.read(quizGameProvider.notifier).hideFeedback();

        // 提交答案到服务（会触发题目索引更新，自动清除选中状态）
        if (widget.isHost) {
          widget.hostService!.gameController.submitAnswer(
            'host',
            originalIndices,
          );
        } else {
          widget.clientService!.submitAnswer(originalIndices);
        }
      });
    });
  }

  void _navigateToResult() {
    final gameState = ref.read(quizGameProvider);

    // 防止重复导航
    if (gameState.hasNavigatedToResult) return;

    ref.read(quizGameProvider.notifier).markNavigatedToResult();

    final room = gameState.room;
    if (room == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          room: room,
          isHost: widget.isHost,
          hostService: widget.hostService,
          clientService: widget.clientService,
        ),
      ),
    );
  }
}
