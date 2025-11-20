/// 题型枚举
enum QuestionType {
  singleChoice, // 单选题
  trueFalse, // 判断题
  multipleChoice; // 多选题

  String get label {
    switch (this) {
      case QuestionType.singleChoice:
        return '单选题';
      case QuestionType.trueFalse:
        return '判断题';
      case QuestionType.multipleChoice:
        return '多选题';
    }
  }
}

/// 题目模型
class Question {
  final String id;
  final String question;
  final List<String> options;
  final QuestionType type; // 题型
  final dynamic correctAnswer; // 正确答案（单选/判断：int，多选：List<int>）

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.type = QuestionType.singleChoice, // 默认单选题
  });

  /// 判断答案是否正确
  bool isAnswerCorrect(dynamic answer) {
    if (answer == null) return false;

    switch (type) {
      case QuestionType.singleChoice:
      case QuestionType.trueFalse:
        return answer == correctAnswer;

      case QuestionType.multipleChoice:
        if (answer is! List || correctAnswer is! List) {
          return false;
        }
        final answerList = (answer).cast<int>()..sort();
        final correctList = (correctAnswer as List).cast<int>()..sort();
        if (answerList.length != correctList.length) return false;
        for (int i = 0; i < answerList.length; i++) {
          if (answerList[i] != correctList[i]) return false;
        }
        return true;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'options': options,
    'type': type.name,
    'correctAnswer': correctAnswer,
  };

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json['id'],
    question: json['question'],
    options: List<String>.from(json['options']),
    type: QuestionType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => QuestionType.singleChoice,
    ),
    correctAnswer: json['correctAnswer'],
  );

  /// 兼容旧版本的构造方法（使用 correctAnswerIndex）
  factory Question.fromLegacy({
    required String id,
    required String question,
    required List<String> options,
    required int correctAnswerIndex,
  }) => Question(
    id: id,
    question: question,
    options: options,
    correctAnswer: correctAnswerIndex,
    type: QuestionType.singleChoice,
  );

  /// 获取正确答案索引（仅用于单选题/判断题）
  int? get correctAnswerIndex {
    if (type == QuestionType.multipleChoice) return null;
    return correctAnswer as int?;
  }
}
