import 'package:flutter/foundation.dart';

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

/// 答案密封类
sealed class Answer {
  const Answer();
}

/// 单选/判断答案
class SingleChoiceAnswer extends Answer {
  final int index;
  const SingleChoiceAnswer(this.index);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SingleChoiceAnswer &&
          runtimeType == other.runtimeType &&
          index == other.index;

  @override
  int get hashCode => index.hashCode;

  @override
  String toString() => 'SingleChoiceAnswer($index)';
}

/// 多选答案
class MultipleChoiceAnswer extends Answer {
  final List<int> indices;
  const MultipleChoiceAnswer(this.indices);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MultipleChoiceAnswer &&
          runtimeType == other.runtimeType &&
          listEquals(indices, other.indices);

  @override
  int get hashCode => Object.hashAll(indices);

  @override
  String toString() => 'MultipleChoiceAnswer($indices)';
}

/// 题目模型
class Question {
  final String id;
  final String question;
  final List<String> options;
  final QuestionType type; // 题型
  final Answer correctAnswer; // 类型安全

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.type = QuestionType.singleChoice, // 默认单选题
  });

  /// 判断答案是否正确
  bool isAnswerCorrect(Answer answer) {
    return switch ((correctAnswer, answer)) {
      (SingleChoiceAnswer c, SingleChoiceAnswer a) => c.index == a.index,
      (MultipleChoiceAnswer c, MultipleChoiceAnswer a) => _listsEqual(
        c.indices,
        a.indices,
      ),
      _ => false,
    };
  }

  /// 辅助方法：比较两个整数列表是否相等（忽略顺序）
  bool _listsEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    final sortedA = List<int>.from(a)..sort();
    final sortedB = List<int>.from(b)..sort();
    for (int i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) return false;
    }
    return true;
  }

  /// 从动态类型创建 Answer 对象
  Answer createAnswerFromDynamic(dynamic value) {
    if (value == null) {
      throw ArgumentError('Answer value cannot be null');
    }

    switch (type) {
      case QuestionType.singleChoice:
      case QuestionType.trueFalse:
        return SingleChoiceAnswer(value as int);
      case QuestionType.multipleChoice:
        return MultipleChoiceAnswer((value as List).cast<int>());
    }
  }

  Map<String, dynamic> toJson() {
    final answerValue = switch (correctAnswer) {
      SingleChoiceAnswer a => a.index,
      MultipleChoiceAnswer a => a.indices,
    };

    return {
      'id': id,
      'question': question,
      'options': options,
      'type': type.name,
      'correctAnswer': answerValue,
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    final type = QuestionType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => QuestionType.singleChoice,
    );

    final dynamic rawAnswer = json['correctAnswer'];
    Answer correctAnswer;

    switch (type) {
      case QuestionType.singleChoice:
      case QuestionType.trueFalse:
        correctAnswer = SingleChoiceAnswer(rawAnswer as int);
        break;
      case QuestionType.multipleChoice:
        correctAnswer = MultipleChoiceAnswer((rawAnswer as List).cast<int>());
        break;
    }

    return Question(
      id: json['id'],
      question: json['question'],
      options: List<String>.from(json['options']),
      type: type,
      correctAnswer: correctAnswer,
    );
  }

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
    correctAnswer: SingleChoiceAnswer(correctAnswerIndex),
    type: QuestionType.singleChoice,
  );

  /// 获取正确答案索引（仅用于单选题/判断题）
  int? get correctAnswerIndex {
    if (correctAnswer is SingleChoiceAnswer) {
      return (correctAnswer as SingleChoiceAnswer).index;
    }
    return null;
  }
}
