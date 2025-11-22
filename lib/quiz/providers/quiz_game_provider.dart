import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz_room_model.dart';
import '../models/question_model.dart';

/// 游戏状态
class QuizGameState {
  final QuizRoom? room;
  final int? selectedAnswer; // 单选题/判断题的选择
  final List<int> selectedAnswers; // 多选题的选择
  final bool showFeedback; // 是否显示反馈弹窗
  final bool isFeedbackCorrect; // 反馈是否正确
  final int currentQuestionIndex; // 当前题目索引
  final List<int> shuffledIndices; // 选项乱序索引
  final bool hasNavigatedToResult; // 是否已导航到结果页
  final bool hasSubmittedAnswer; // 是否已提交答案(用于显示按钮反馈)
  final bool submittedAnswerCorrect; // 提交的答案是否正确

  const QuizGameState({
    this.room,
    this.selectedAnswer,
    this.selectedAnswers = const [],
    this.showFeedback = false,
    this.isFeedbackCorrect = false,
    this.currentQuestionIndex = -1,
    this.shuffledIndices = const [],
    this.hasNavigatedToResult = false,
    this.hasSubmittedAnswer = false,
    this.submittedAnswerCorrect = false,
  });

  /// 获取当前题目
  Question? get currentQuestion {
    if (room == null || currentQuestionIndex < 0) return null;
    if (currentQuestionIndex >= room!.questions.length) return null;
    return room!.questions[currentQuestionIndex];
  }

  /// 复制并修改状态
  QuizGameState copyWith({
    QuizRoom? room,
    int? selectedAnswer,
    bool clearSelectedAnswer = false,
    List<int>? selectedAnswers,
    bool? showFeedback,
    bool? isFeedbackCorrect,
    int? currentQuestionIndex,
    List<int>? shuffledIndices,
    bool? hasNavigatedToResult,
    bool? hasSubmittedAnswer,
    bool? submittedAnswerCorrect,
  }) {
    return QuizGameState(
      room: room ?? this.room,
      selectedAnswer: clearSelectedAnswer
          ? null
          : (selectedAnswer ?? this.selectedAnswer),
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      showFeedback: showFeedback ?? this.showFeedback,
      isFeedbackCorrect: isFeedbackCorrect ?? this.isFeedbackCorrect,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      shuffledIndices: shuffledIndices ?? this.shuffledIndices,
      hasNavigatedToResult: hasNavigatedToResult ?? this.hasNavigatedToResult,
      hasSubmittedAnswer: hasSubmittedAnswer ?? this.hasSubmittedAnswer,
      submittedAnswerCorrect:
          submittedAnswerCorrect ?? this.submittedAnswerCorrect,
    );
  }

  /// 清空选择的答案
  QuizGameState clearSelectedAnswers() {
    return copyWith(clearSelectedAnswer: true, selectedAnswers: const []);
  }
}

/// 游戏状态管理器
class QuizGameNotifier extends StateNotifier<QuizGameState> {
  QuizGameNotifier() : super(const QuizGameState());

  /// 更新房间状态
  void updateRoom(QuizRoom room, {int? playerQuestionIndex}) {
    state = state.copyWith(room: room);
    _updateQuestionState(room, playerQuestionIndex);
  }

  /// 更新题目状态(处理乱序)
  void _updateQuestionState(QuizRoom room, int? playerQuestionIndex) {
    // 使用玩家的题目索引(独立进度模式)或房间的题目索引
    final newIndex = playerQuestionIndex ?? room.currentQuestionIndex;

    // 如果题目索引变化,重新生成乱序索引并清空选择
    if (newIndex != state.currentQuestionIndex) {
      final question = room.questions[newIndex];
      final shuffled = List<int>.generate(
        question.options.length,
        (index) => index,
      )..shuffle();

      state = state.copyWith(
        currentQuestionIndex: newIndex,
        shuffledIndices: shuffled,
        clearSelectedAnswer: true,
        selectedAnswers: const [],
        showFeedback: false,
        hasSubmittedAnswer: false,
        submittedAnswerCorrect: false,
      );
    }
  }

  /// 选择单选答案
  void selectSingleAnswer(int index) {
    state = state.copyWith(selectedAnswer: index);
  }

  /// 切换多选答案
  void toggleMultipleChoice(int index) {
    final newSelected = List<int>.from(state.selectedAnswers);
    if (newSelected.contains(index)) {
      newSelected.remove(index);
    } else {
      newSelected.add(index);
    }
    state = state.copyWith(selectedAnswers: newSelected);
  }

  /// 显示反馈
  void showFeedback(bool isCorrect) {
    state = state.copyWith(
      showFeedback: true,
      isFeedbackCorrect: isCorrect,
      hasSubmittedAnswer: true,
      submittedAnswerCorrect: isCorrect,
    );
  }

  /// 隐藏反馈
  void hideFeedback() {
    state = state.copyWith(showFeedback: false);
  }

  /// 标记已导航到结果页
  void markNavigatedToResult() {
    state = state.copyWith(hasNavigatedToResult: true);
  }

  /// 重置状态
  void reset() {
    state = const QuizGameState();
  }
}

/// 游戏状态 Provider
final quizGameProvider = StateNotifierProvider<QuizGameNotifier, QuizGameState>(
  (ref) {
    return QuizGameNotifier();
  },
);
