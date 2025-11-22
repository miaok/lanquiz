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
import 'widgets/exit_confirm_dialog.dart';
import 'mixins/game_listeners_mixin.dart';
import 'mixins/answer_handler_mixin.dart';

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

class _QuizGameScreenState extends ConsumerState<QuizGameScreen>
    with GameListenersMixin, AnswerHandlerMixin, AutomaticKeepAliveClientMixin {
  // Mixin 接口实现
  @override
  QuizHostService? get hostService => widget.hostService;

  @override
  QuizClientService? get clientService => widget.clientService;

  @override
  bool get isHost => widget.isHost;

  @override
  String get myPlayerId {
    if (widget.isHost) {
      return 'host';
    } else {
      return widget.clientService!.myPlayerId ?? '';
    }
  }

  @override
  void initState() {
    super.initState();
    // 重置状态，确保每次进入页面都是新的开始
    Future.microtask(() {
      ref.read(quizGameProvider.notifier).reset();
    });
    setupGameListeners(onNavigateToResult: _navigateToResult);
  }

  @override
  void dispose() {
    disposeGameListeners();
    disposeFeedbackTimer();
    super.dispose();
  }

  /// 根据得分对比生成AppBar标题
  String _getAppBarTitle(QuizPlayer myPlayer, QuizRoom room) {
    // 找到对手
    final opponent = room.players.firstWhere(
      (p) => p.id != myPlayerId,
      orElse: () => myPlayer,
    );

    // 如果没有对手，只显示题目进度
    if (opponent.id == myPlayer.id) {
      return '自由练习';
    }

    // 计算得分占比
    final total = myPlayer.score + opponent.score;
    final myRatio = total > 0 ? myPlayer.score / total : 0.5;

    // 根据占比生成状态文本
    if (myRatio >= 0.7) {
      return '遥遥领先';
    } else if (myRatio >= 0.6) {
      return '稳稳领先';
    } else if (myRatio > 0.5) {
      return '略有优势';
    } else if (myRatio == 0.5) {
      return '棋逢对手';
    } else if (myRatio >= 0.4) {
      return '加油加油';
    } else if (myRatio >= 0.3) {
      return '奋起直追';
    } else {
      return '别放弃';
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // 从Provider读取状态
    final gameState = ref.watch(quizGameProvider);
    final room = gameState.room;

    if (room == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 获取当前玩家
    final myPlayer = room.players.firstWhere(
      (p) => p.id == myPlayerId,
      orElse: () => room.players.first,
    );

    // 如果已完成所有题目，显示等待界面
    if (myPlayer.isFinished) {
      return WaitingScreen(
        room: room,
        myPlayerId: myPlayerId,
        onShowExitDialog: _showExitConfirmDialog,
      );
    }

    // 获取当前题目
    if (myPlayer.currentQuestionIndex >= room.questions.length) {
      return const Scaffold(body: Center(child: Text('题目索引超出范围')));
    }

    final question = room.questions[myPlayer.currentQuestionIndex];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
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
        body: SafeArea(
          child: Column(
            children: [
              // 得分榜
              PlayerScoreBoard(
                players: room.players,
                myPlayerId: myPlayerId,
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
                      ...gameState.shuffledIndices.asMap().entries.map((entry) {
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
                              selectSingleAnswer(displayIndex, question),
                          onToggleMultiple: () =>
                              toggleMultipleChoice(displayIndex),
                          hasSubmittedAnswer: gameState.hasSubmittedAnswer,
                          submittedAnswerCorrect:
                              gameState.submittedAnswerCorrect,
                        );
                      }),

                      // 多选题确认按钮
                      if (question.type == QuestionType.multipleChoice &&
                          myPlayer.currentAnswer == null) ...[
                        const SizedBox(height: 24),
                        ConfirmButton(
                          selectedCount: gameState.selectedAnswers.length,
                          totalCount: question.options.length,
                          onConfirm: () => confirmMultipleChoice(question),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitConfirmDialog() {
    ExitConfirmDialog.show(
      context,
      isHost: widget.isHost,
      hostService: widget.hostService,
      clientService: widget.clientService,
    );
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
