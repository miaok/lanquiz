import '../models/question.dart';

/// 模拟题库数据
class SampleQuestions {
  static List<Question> getQuestions() {
    return [
      // 单选题
      Question(
        id: 'q1',
        type: QuestionType.singleChoice,
        question: 'Flutter使用的编程语言是什么？',
        options: ['Java', 'Kotlin', 'Dart', 'Swift'],
        correctAnswer: 2,
      ),

      // 判断题
      Question(
        id: 'q2',
        type: QuestionType.trueFalse,
        question: 'Flutter 是 Google 开发的跨平台 UI 框架',
        options: ['对', '错'],
        correctAnswer: 0, // 0=对, 1=错
      ),

      // 多选题
      Question(
        id: 'q3',
        type: QuestionType.multipleChoice,
        question: '以下哪些是 Flutter 的布局 Widget？（多选）',
        options: ['Column', 'Row', 'Text', 'Container'],
        correctAnswer: [0, 1, 3], // Column, Row, Container
      ),

      // 单选题
      Question(
        id: 'q4',
        type: QuestionType.singleChoice,
        question: 'StatefulWidget和StatelessWidget的主要区别是什么？',
        options: [
          'StatefulWidget可以有状态',
          'StatelessWidget性能更好',
          'StatefulWidget只能用于复杂界面',
          '没有区别',
        ],
        correctAnswer: 0,
      ),

      // 判断题
      Question(
        id: 'q5',
        type: QuestionType.trueFalse,
        question: 'Flutter 只能开发移动应用',
        options: ['对', '错'],
        correctAnswer: 1, // 错
      ),

      // 多选题
      Question(
        id: 'q6',
        type: QuestionType.multipleChoice,
        question: '以下哪些是 Flutter 的状态管理方案？（多选）',
        options: ['Provider', 'Redux', 'Bloc', 'MVC'],
        correctAnswer: [0, 1, 2], // Provider, Redux, Bloc
      ),

      // 单选题
      Question(
        id: 'q7',
        type: QuestionType.singleChoice,
        question: 'pubspec.yaml文件的主要作用是？',
        options: ['配置路由', '管理依赖', '定义主题', '设置权限'],
        correctAnswer: 1,
      ),

      // 判断题
      Question(
        id: 'q8',
        type: QuestionType.trueFalse,
        question: 'Flutter 使用 Skia 图形引擎进行渲染',
        options: ['对', '错'],
        correctAnswer: 0, // 对
      ),

      // 多选题
      Question(
        id: 'q9',
        type: QuestionType.multipleChoice,
        question: '以下哪些方法可以在 Flutter 中实现页面导航？（多选）',
        options: [
          'Navigator.push()',
          'Navigator.pop()',
          'Navigator.pushNamed()',
          'Navigator.remove()',
        ],
        correctAnswer: [0, 1, 2], // push, pop, pushNamed
      ),

      // 单选题
      Question(
        id: 'q10',
        type: QuestionType.singleChoice,
        question: 'Flutter中的async和await关键字用于？',
        options: ['异步编程', '同步编程', '线程管理', '内存管理'],
        correctAnswer: 0,
      ),
    ];
  }

  /// 获取指定数量的随机题目
  static List<Question> getRandomQuestions(int count) {
    final allQuestions = getQuestions();
    allQuestions.shuffle();
    return allQuestions.take(count).toList();
  }

  /// 按题型获取题目
  static List<Question> getQuestionsByType(QuestionType type) {
    return getQuestions().where((q) => q.type == type).toList();
  }

  /// 获取指定题型和数量的随机题目
  static List<Question> getRandomQuestionsByType(
    QuestionType type,
    int count,
  ) {
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
