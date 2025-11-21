import 'dart:async';
import '../models/quiz_room.dart';
import '../models/player.dart';
import '../models/question.dart';

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

    // 使用题目的判题方法
    final isCorrect = question.isAnswerCorrect(answerIndex);

    // 立即计算分数
    int newScore = player.score;
    int newComboCount = player.comboCount;
    AnswerResult answerResult;

    if (isCorrect) {
      final baseScore = (100 / room.questions.length).round(); // 每题默认分数
      final totalScore = baseScore; // 取消时间奖励
      newScore = player.score + totalScore;
      newComboCount = player.comboCount + 1; // 连击数+1
      answerResult = AnswerResult.correct;
      // print(
      //   '玩家 ${player.name} 答对了!基础分: $baseScore, 连击: $newComboCount, 新总分: $newScore',
      // );
    } else {
      newComboCount = 0; // 答错重置连击数
      answerResult = AnswerResult.incorrect;
      // print('玩家 ${player.name} 答错了,连击中断');
    }

    // 判断是否是最后一题
    final isLastQuestion =
        player.currentQuestionIndex >= room.questions.length - 1;

    // 记录错题
    List<Map<String, dynamic>> updatedWrongAnswers = List.from(
      player.wrongAnswers,
    );
    if (!isCorrect) {
      updatedWrongAnswers.add({
        'questionId': question.id,
        'playerAnswer': answerIndex,
        'correctAnswer': question.correctAnswer,
      });
    }

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
      // print('所有玩家都已完成所有题目，游戏结束');
      room = room.copyWith(status: RoomStatus.finished);
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

  /// 重新开始游戏
  void restartGame([List<Question>? newQuestions]) {
    List<QuizPlayer> updatedPlayers = [];
    for (int i = 0; i < room.players.length; i++) {
      final player = room.players[i];
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
  List<QuizPlayer> getLeaderboard() {
    final sortedPlayers = List<QuizPlayer>.from(room.players);
    sortedPlayers.sort((a, b) => b.score.compareTo(a.score));
    return sortedPlayers;
  }

  void _notifyUpdate() {
    // print('GameController._notifyUpdate() - 触发房间更新通知');
    if (!_roomUpdateController.isClosed) {
      _roomUpdateController.add(room);
      // print('房间更新通知已发送到stream');
    } else {
      // print('警告：StreamController已关闭，无法发送更新');
    }
  }

  void dispose() {
    if (!_roomUpdateController.isClosed) {
      _roomUpdateController.close();
    }
  }
}
