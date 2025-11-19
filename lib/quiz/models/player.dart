/// 答题结果枚举
enum AnswerResult {
  none, // 未答题或等待中
  correct, // 答对
  incorrect, // 答错
}

/// 玩家模型
class QuizPlayer {
  final String id;
  final String name;
  int score;
  bool isReady;
  dynamic currentAnswer; // 当前题的答案（单选/判断：int，多选：List<int>）
  int answerTime; // 答题用时（毫秒）
  int currentQuestionIndex; // 当前题目索引（每个玩家独立）
  bool isFinished; // 是否完成所有题目
  int comboCount; // 连击数(连续答对的题目数)
  AnswerResult lastAnswerResult; // 最后一次答题结果

  QuizPlayer({
    required this.id,
    required this.name,
    this.score = 0,
    this.isReady = false,
    this.currentAnswer,
    this.answerTime = 0,
    this.currentQuestionIndex = 0,
    this.isFinished = false,
    this.comboCount = 0,
    this.lastAnswerResult = AnswerResult.none,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'score': score,
    'isReady': isReady,
    'currentAnswer': currentAnswer,
    'answerTime': answerTime,
    'currentQuestionIndex': currentQuestionIndex,
    'isFinished': isFinished,
    'comboCount': comboCount,
    'lastAnswerResult': lastAnswerResult.index,
  };

  factory QuizPlayer.fromJson(Map<String, dynamic> json) => QuizPlayer(
    id: json['id'],
    name: json['name'],
    score: json['score'] ?? 0,
    isReady: json['isReady'] ?? false,
    currentAnswer: json['currentAnswer'],
    answerTime: json['answerTime'] ?? 0,
    currentQuestionIndex: json['currentQuestionIndex'] ?? 0,
    isFinished: json['isFinished'] ?? false,
    comboCount: json['comboCount'] ?? 0,
    lastAnswerResult: AnswerResult.values[json['lastAnswerResult'] ?? 0],
  );

  QuizPlayer copyWith({
    String? id,
    String? name,
    int? score,
    bool? isReady,
    dynamic currentAnswer,
    int? answerTime,
    int? currentQuestionIndex,
    bool? isFinished,
    int? comboCount,
    AnswerResult? lastAnswerResult,
    bool forceNullCurrentAnswer = false,
  }) {
    return QuizPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      score: score ?? this.score,
      isReady: isReady ?? this.isReady,
      currentAnswer: forceNullCurrentAnswer
          ? null
          : (currentAnswer ?? this.currentAnswer),
      answerTime: answerTime ?? this.answerTime,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      isFinished: isFinished ?? this.isFinished,
      comboCount: comboCount ?? this.comboCount,
      lastAnswerResult: lastAnswerResult ?? this.lastAnswerResult,
    );
  }
}
