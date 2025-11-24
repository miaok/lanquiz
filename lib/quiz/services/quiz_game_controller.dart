import 'dart:async';
import '../models/quiz_room_model.dart';
import '../models/player_model.dart';
import '../models/question_model.dart';
import '../utils/app_logger.dart';

/// 知识竞答游戏控制器
class QuizGameController {
  QuizRoom room;
  final StreamController<QuizRoom> _roomUpdateController =
      StreamController.broadcast();

  Stream<QuizRoom> get roomUpdates => _roomUpdateController.stream;

  QuizGameController(this.room);

  /// 添加玩家
  bool addPlayer(QuizPlayer player) {
    if (room.isFull) return false;
    if (room.players.any((p) => p.id == player.id)) return false;

    room = room.copyWith(players: [...room.players, player]);
    _notifyUpdate();
    return true;
  }

  /// 移除玩家
  void removePlayer(String playerId) {
    final updatedPlayers = List<QuizPlayer>.from(room.players);
    updatedPlayers.removeWhere((p) => p.id == playerId);
    room = room.copyWith(players: updatedPlayers);
    _notifyUpdate();
  }

  /// 玩家准备
  void playerReady(String playerId, bool isReady) {
    final player = room.players.firstWhere((p) => p.id == playerId);
    final index = room.players.indexOf(player);
    final updatedPlayers = List<QuizPlayer>.from(room.players);
    updatedPlayers[index] = player.copyWith(isReady: isReady);
    room = room.copyWith(players: updatedPlayers);
    _notifyUpdate();
  }

  /// 开始游戏
  bool startGame() {
    if (!room.allPlayersReady) return false;
    if (room.questions.isEmpty) return false;

    List<QuizPlayer> updatedPlayers = [];
    for (int i = 0; i < room.players.length; i++) {
      updatedPlayers.add(
        room.players[i].copyWith(
          answerTime: 0,
          forceNullCurrentAnswer: true,
          currentQuestionIndex: 0,
          isFinished: false,
          comboCount: 0,
          lastAnswerResult: AnswerResult.none,
          wrongAnswers: [],
        ),
      );
    }

    room = room.copyWith(
      status: RoomStatus.playing,
      currentQuestionIndex: 0,
      questionStartTime: DateTime.now(),
      players: updatedPlayers,
    );

    _notifyUpdate();
    return true;
  }

  /// 玩家提交答案（完全独立模式：每个玩家独立进度）
  void submitAnswer(String playerId, dynamic answerIndex) {
    if (room.status != RoomStatus.playing) return;

    final player = room.players.firstWhere((p) => p.id == playerId);
    final index = room.players.indexOf(player);

    // 获取玩家当前的题目
    final question = room.questions[player.currentQuestionIndex];
    final answerTime = DateTime.now()
        .difference(room.questionStartTime!)
        .inMilliseconds;

    // 将动态类型的答案转换为 Answer 对象
    final answerObject = question.createAnswerFromDynamic(answerIndex);

    // 使用题目的判题方法
    final isCorrect = question.isAnswerCorrect(answerObject);

    // 简化的计分规则：答对得分，答错不得分
    int newScore = player.score;
    int newComboCount = player.comboCount;
    AnswerResult answerResult;

    if (isCorrect) {
      final baseScore = (100 / room.questions.length).round(); // 每题平均分数
      newScore = player.score + baseScore;
      newComboCount = player.comboCount + 1; // 连击数+1
      answerResult = AnswerResult.correct;
    } else {
      newComboCount = 0; // 答错重置连击数
      answerResult = AnswerResult.incorrect;
    }

    // 记录错题
    List<Map<String, dynamic>> updatedWrongAnswers = List.from(
      player.wrongAnswers,
    );
    if (!isCorrect) {
      // 获取正确答案的原始值以便存储
      final correctAnswerValue = switch (question.correctAnswer) {
        SingleChoiceAnswer a => a.index,
        MultipleChoiceAnswer a => a.indices,
      };

      updatedWrongAnswers.add({
        'questionId': question.id,
        'playerAnswer': answerIndex,
        'correctAnswer': correctAnswerValue,
      });
    }

    // 判断是否是最后一题
    final isLastQuestion =
        player.currentQuestionIndex >= room.questions.length - 1;

    // 强制模式逻辑：答错不跳转下一题
    if (room.gameMode == GameMode.force && !isCorrect) {
      final updatedPlayers = List<QuizPlayer>.from(room.players);
      updatedPlayers[index] = player.copyWith(
        currentAnswer: null, // 重置答案
        forceNullCurrentAnswer: true,
        // 关键：不更新 answerTime，这样最终答对时计算的时间才是这道题的总耗时
        answerTime: player.answerTime,
        score: newScore,
        comboCount: 0,
        lastAnswerResult: AnswerResult.incorrect,
        wrongAnswers: updatedWrongAnswers,
        currentQuestionIndex: player.currentQuestionIndex, // 保持在当前题目
        isFinished: false,
      );
      room = room.copyWith(players: updatedPlayers);
      _notifyUpdate();
      return;
    }

    // 简化的计分逻辑：答对得分，答错不得分
    // 不再区分游戏模式，统一使用相同的计分规则

    final updatedPlayers = List<QuizPlayer>.from(room.players);
    updatedPlayers[index] = player.copyWith(
      currentAnswer: answerIndex,
      answerTime: answerTime,
      score: newScore,
      comboCount: newComboCount,
      lastAnswerResult: answerResult,
      wrongAnswers: updatedWrongAnswers,
      // 如果不是最后一题，自动进入下一题
      currentQuestionIndex: isLastQuestion
          ? player.currentQuestionIndex
          : player.currentQuestionIndex + 1,
      isFinished: isLastQuestion,
      // 如果不是最后一题，清空当前答案以便显示下一题
      forceNullCurrentAnswer: !isLastQuestion,
    );
    room = room.copyWith(players: updatedPlayers);

    _notifyUpdate();

    // 检查是否所有人都完成了所有题目
    if (room.allPlayersFinished) {
      appLogger.i('所有玩家都已完成所有题目，游戏结束');
      room = room.copyWith(
        status: RoomStatus.finished,
        gameEndTime: DateTime.now(), // 记录游戏结束时间
      );
      _notifyUpdate();
    }
  }

  /// 更新题目列表（仅在等待阶段允许）
  bool updateQuestions(List<Question> newQuestions) {
    if (room.status != RoomStatus.waiting) return false;
    if (newQuestions.isEmpty) return false;

    room = room.copyWith(questions: newQuestions);
    _notifyUpdate();
    return true;
  }

  /// 更新游戏模式
  bool updateGameMode(GameMode mode) {
    if (room.status != RoomStatus.waiting) return false;
    room = room.copyWith(gameMode: mode);
    _notifyUpdate();
    return true;
  }

  /// 重新开始游戏
  /// [newQuestions] 新的题目列表
  /// [keepPlayerIds] 要保留的玩家ID列表（如果为null则保留所有玩家）
  void restartGame([List<Question>? newQuestions, Set<String>? keepPlayerIds]) {
    appLogger.i('重新开始游戏 - 当前玩家数: ${room.players.length}');
    if (keepPlayerIds != null) {
      appLogger.i('要保留的玩家ID: $keepPlayerIds');
    }

    List<QuizPlayer> updatedPlayers = [];

    for (int i = 0; i < room.players.length; i++) {
      final player = room.players[i];

      // 如果指定了要保留的玩家ID列表，则只保留这些玩家
      if (keepPlayerIds != null && !keepPlayerIds.contains(player.id)) {
        appLogger.i('移除已断开连接的玩家: ${player.name} (${player.id})');
        continue;
      }

      appLogger.d('保留玩家: ${player.name} (${player.id})');
      updatedPlayers.add(
        player.copyWith(
          score: 0,
          // 房主默认准备好，其他玩家需要重新准备
          isReady: player.id == 'host',
          answerTime: 0,
          forceNullCurrentAnswer: true,
          currentQuestionIndex: 0,
          isFinished: false,
          comboCount: 0,
          lastAnswerResult: AnswerResult.none,
          wrongAnswers: [], // Reset wrong answers on game restart
        ),
      );
    }

    appLogger.i('游戏重置完成 - 保留玩家数: ${updatedPlayers.length}');

    room = room.copyWith(
      status: RoomStatus.waiting,
      currentQuestionIndex: 0,
      questionStartTime: null,
      players: updatedPlayers,
      questions: newQuestions ?? room.questions,
    );

    _notifyUpdate();
  }

  /// 获取排行榜
  /// 排序规则：
  /// 快速模式:
  ///   1. 分数高的排在前面
  ///   2. 分数相同时，用时少的排在前面（answerTime越小越好）
  /// 强制模式:
  ///   1. 错题数少的排在前面
  ///   2. 错题数相同时，用时少的排在前面
  List<QuizPlayer> getLeaderboard() {
    final sortedPlayers = List<QuizPlayer>.from(room.players);

    if (room.gameMode == GameMode.force) {
      // 强制模式：按错题数和用时排序
      sortedPlayers.sort((a, b) {
        // 首先按错题数升序排序（错题少的排前面）
        final wrongCountComparison = a.wrongAnswers.length.compareTo(
          b.wrongAnswers.length,
        );
        if (wrongCountComparison != 0) {
          return wrongCountComparison;
        }
        // 错题数相同时，按用时升序排序（用时少的排前面）
        return a.answerTime.compareTo(b.answerTime);
      });
    } else {
      // 快速模式：按分数和用时排序
      sortedPlayers.sort((a, b) {
        // 首先按分数降序排序
        final scoreComparison = b.score.compareTo(a.score);
        if (scoreComparison != 0) {
          return scoreComparison;
        }
        // 分数相同时，按用时升序排序（用时少的排前面）
        return a.answerTime.compareTo(b.answerTime);
      });
    }

    return sortedPlayers;
  }

  void _notifyUpdate() {
    appLogger.d('GameController._notifyUpdate() - 触发房间更新通知');
    if (!_roomUpdateController.isClosed) {
      _roomUpdateController.add(room);
      appLogger.d('房间更新通知已发送到stream');
    } else {
      appLogger.w('警告：StreamController已关闭，无法发送更新');
    }
  }

  void dispose() {
    if (!_roomUpdateController.isClosed) {
      _roomUpdateController.close();
    }
  }
}
