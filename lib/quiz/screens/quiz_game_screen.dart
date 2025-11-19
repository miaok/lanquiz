import 'dart:async';
import 'package:flutter/material.dart';
import '../models/quiz_room.dart';
import '../models/question.dart';
import '../services/quiz_host_service.dart';
import '../services/quiz_client_service.dart';
import 'quiz_result_screen.dart';
import 'widgets/player_score_board.dart';
import 'widgets/question_card.dart';
import 'widgets/option_button.dart';
import 'widgets/confirm_button.dart';
import 'widgets/waiting_screen.dart';
import 'widgets/answer_feedback_overlay.dart';

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

  // 反馈弹窗状态
  bool _showFeedback = false;
  bool _isFeedbackCorrect = false;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    if (widget.isHost) {
      _room = widget.hostService!.gameController.room;
      _roomSubscription = widget.hostService!.gameController.roomUpdates.listen(
        (room) {
          if (mounted) {
            setState(() {
              _checkForQuestionChange(room);
              _room = room;

              if (room.status == RoomStatus.finished) {
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
            _checkForQuestionChange(room);
            _room = room;

            if (room.status == RoomStatus.finished) {
              _navigateToResult();
            }
          });
        }
      });
    }
  }

  void _checkForQuestionChange(QuizRoom newRoom) {
    if (_room == null) return;

    final oldPlayer = _room!.players.firstWhere(
      (p) => p.id == _myPlayerId,
      orElse: () => _room!.players.first,
    );
    final newPlayer = newRoom.players.firstWhere(
      (p) => p.id == _myPlayerId,
      orElse: () => newRoom.players.first,
    );

    if (newPlayer.currentQuestionIndex != oldPlayer.currentQuestionIndex) {
      _selectedAnswer = null;
      _selectedAnswers.clear();
      _showFeedback = false;
    }
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();

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
            '第 ${myPlayer.currentQuestionIndex + 1}/${_room!.questions.length} 题',
          ),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
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
                          QuestionCard(questionText: question.question),
                          const SizedBox(height: 16),

                          // 选项
                          ...List.generate(
                            question.options.length,
                            (index) => OptionButton(
                              question: question,
                              index: index,
                              hasAnswered: myPlayer.currentAnswer != null,
                              selectedAnswer: _selectedAnswer,
                              selectedAnswers: _selectedAnswers,
                              onSelectSingle: () =>
                                  _selectSingleAnswer(index, question),
                              onToggleMultiple: () =>
                                  _toggleMultipleChoice(index),
                            ),
                          ),

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
        title: const Text('退出游戏'),
        content: const Text('确定要退出游戏吗？游戏进度将会丢失。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 关闭对话框
              Navigator.of(context).popUntil((route) => route.isFirst); // 返回主页
            },
            child: const Text('退出', style: TextStyle(color: Colors.red)),
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
    Future.delayed(const Duration(milliseconds: 200), () {
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
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      if (widget.isHost) {
        widget.hostService!.gameController.submitAnswer('host', sortedAnswers);
      } else {
        widget.clientService!.submitAnswer(sortedAnswers);
      }
    });
  }

  void _navigateToResult() {
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
