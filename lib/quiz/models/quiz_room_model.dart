import 'player_model.dart';
import 'question_model.dart';

/// 房间状态
enum RoomStatus {
  waiting, // 等待玩家
  ready, // 准备开始
  playing, // 游戏中
  showingAnswer, // 显示答案
  finished, // 游戏结束
}

/// 知识竞答房间模型
class QuizRoom {
  final String id;
  final String name;
  final String hostId;
  final int maxPlayers;
  List<QuizPlayer> players;
  List<Question> questions;
  int currentQuestionIndex;
  RoomStatus status;
  DateTime? questionStartTime;
  DateTime? gameEndTime; // 游戏结束时间

  QuizRoom({
    required this.id,
    required this.name,
    required this.hostId,
    this.maxPlayers = 4,
    List<QuizPlayer>? players,
    List<Question>? questions,
    this.currentQuestionIndex = 0,
    this.status = RoomStatus.waiting,
    this.questionStartTime,
    this.gameEndTime,
  }) : players = players ?? [],
       questions = questions ?? [];

  Question? get currentQuestion => currentQuestionIndex < questions.length
      ? questions[currentQuestionIndex]
      : null;

  bool get isFull => players.length >= maxPlayers;

  bool get allPlayersReady =>
      players.isNotEmpty && players.every((p) => p.isReady);

  bool get allPlayersFinished =>
      players.isNotEmpty && players.every((p) => p.isFinished);

  bool get isLastQuestion => currentQuestionIndex >= questions.length - 1;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'hostId': hostId,
    'maxPlayers': maxPlayers,
    'players': players.map((p) => p.toJson()).toList(),
    'questions': questions.map((q) => q.toJson()).toList(),
    'currentQuestionIndex': currentQuestionIndex,
    'status': status.name,
    'questionStartTime': questionStartTime?.toIso8601String(),
    'gameEndTime': gameEndTime?.toIso8601String(),
  };

  factory QuizRoom.fromJson(Map<String, dynamic> json) => QuizRoom(
    id: json['id'],
    name: json['name'],
    hostId: json['hostId'],
    maxPlayers: json['maxPlayers'] ?? 4,
    players:
        (json['players'] as List?)
            ?.map((p) => QuizPlayer.fromJson(p))
            .toList() ??
        [],
    questions:
        (json['questions'] as List?)
            ?.map((q) => Question.fromJson(q))
            .toList() ??
        [],
    currentQuestionIndex: json['currentQuestionIndex'] ?? 0,
    status: RoomStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => RoomStatus.waiting,
    ),
    questionStartTime: json['questionStartTime'] != null
        ? DateTime.parse(json['questionStartTime'])
        : null,
    gameEndTime: json['gameEndTime'] != null
        ? DateTime.parse(json['gameEndTime'])
        : null,
  );

  QuizRoom copyWith({
    String? id,
    String? name,
    String? hostId,
    int? maxPlayers,
    List<QuizPlayer>? players,
    List<Question>? questions,
    int? currentQuestionIndex,
    RoomStatus? status,
    DateTime? questionStartTime,
    DateTime? gameEndTime,
  }) {
    return QuizRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      hostId: hostId ?? this.hostId,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      players: players ?? this.players,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      status: status ?? this.status,
      questionStartTime: questionStartTime ?? this.questionStartTime,
      gameEndTime: gameEndTime ?? this.gameEndTime,
    );
  }
}
