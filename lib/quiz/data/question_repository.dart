import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question.dart';

/// 题目数据仓库
class QuestionRepository {
  static List<Question> _questions = [];
  static bool _isLoaded = false;

  /// 从 JSON 资源加载题目
  static Future<void> loadQuestions() async {
    if (_isLoaded) return;

    final stopwatch = Stopwatch()..start();
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/questions.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);
      _questions = jsonList.map((json) => Question.fromJson(json)).toList();
      _isLoaded = true;
      stopwatch.stop();
      print(
        'Loaded ${_questions.length} questions from JSON in ${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (e) {
      print('Error loading questions: $e');
      _questions = [];
    }
  }

  static List<Question> getQuestions() {
    return _questions;
  }

  /// 获取指定数量的随机题目
  static List<Question> getRandomQuestions(int count) {
    final allQuestions = List<Question>.from(_questions);
    allQuestions.shuffle();
    return allQuestions.take(count).toList();
  }

  /// 按题型获取题目
  static List<Question> getQuestionsByType(QuestionType type) {
    return _questions.where((q) => q.type == type).toList();
  }

  /// 获取指定题型和数量的随机题目
  static List<Question> getRandomQuestionsByType(QuestionType type, int count) {
    final questions = getQuestionsByType(type);
    questions.shuffle();
    return questions.take(count).toList();
  }

  /// 按照题型数量配置获取题目（顺序：判断→单选→多选）
  static List<Question> getQuestionsByConfig({
    required int trueFalseCount,
    required int singleChoiceCount,
    required int multipleChoiceCount,
  }) {
    final List<Question> result = [];

    // 1. 先添加判断题
    if (trueFalseCount > 0) {
      result.addAll(
        getRandomQuestionsByType(QuestionType.trueFalse, trueFalseCount),
      );
    }

    // 2. 再添加单选题
    if (singleChoiceCount > 0) {
      result.addAll(
        getRandomQuestionsByType(QuestionType.singleChoice, singleChoiceCount),
      );
    }

    // 3. 最后添加多选题
    if (multipleChoiceCount > 0) {
      result.addAll(
        getRandomQuestionsByType(
          QuestionType.multipleChoice,
          multipleChoiceCount,
        ),
      );
    }

    return result;
  }
}
