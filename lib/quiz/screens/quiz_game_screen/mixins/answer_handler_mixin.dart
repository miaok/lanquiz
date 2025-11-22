import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/question_model.dart';
import '../../../providers/quiz_game_provider.dart';
import '../../../services/quiz_host_service.dart';
import '../../../services/quiz_client_service.dart';

/// 答题逻辑 Mixin
/// 负责处理单选、多选题的答题逻辑
mixin AnswerHandlerMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  QuizHostService? get hostService;
  QuizClientService? get clientService;
  bool get isHost;

  Timer? feedbackTimer;

  /// 单选题/判断题选择
  void selectSingleAnswer(int displayIndex, Question question) {
    final gameState = ref.read(quizGameProvider);

    // 如果正在显示反馈,忽略点击
    if (gameState.showFeedback) return;

    // 获取原始索引
    final originalIndex = gameState.shuffledIndices[displayIndex];

    // 更新Provider状态 - 显示选中效果
    ref.read(quizGameProvider.notifier).selectSingleAnswer(displayIndex);

    // 检查答案是否正确
    final isCorrect = question.isAnswerCorrect(
      SingleChoiceAnswer(originalIndex),
    );

    // 延迟显示反馈,让用户看到选中的高亮效果
    feedbackTimer?.cancel();
    feedbackTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      // 显示反馈(在按钮上显示)
      ref.read(quizGameProvider.notifier).showFeedback(isCorrect);

      // 延迟后提交答案并隐藏反馈
      feedbackTimer = Timer(const Duration(milliseconds: 800), () {
        if (!mounted) return;

        // 隐藏反馈(选中状态会在题目索引变化时自动清除)
        ref.read(quizGameProvider.notifier).hideFeedback();

        // 提交答案到服务(会触发题目索引更新,自动清除选中状态)
        if (isHost) {
          hostService!.gameController.submitAnswer('host', originalIndex);
        } else {
          clientService!.submitAnswer(originalIndex);
        }
      });
    });
  }

  /// 多选题切换选项
  void toggleMultipleChoice(int displayIndex) {
    final gameState = ref.read(quizGameProvider);
    if (gameState.showFeedback) return;

    ref.read(quizGameProvider.notifier).toggleMultipleChoice(displayIndex);
  }

  /// 多选题确认答案
  void confirmMultipleChoice(Question question) {
    final gameState = ref.read(quizGameProvider);
    if (gameState.selectedAnswers.isEmpty || gameState.showFeedback) return;

    // 转换为原始索引并排序
    final originalIndices =
        gameState.selectedAnswers
            .map((i) => gameState.shuffledIndices[i])
            .toList()
          ..sort();

    // 检查答案是否正确
    final isCorrect = question.isAnswerCorrect(
      MultipleChoiceAnswer(originalIndices),
    );

    // 延迟显示反馈,让用户看到选中的高亮效果
    feedbackTimer?.cancel();
    feedbackTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      // 显示反馈(在按钮上显示)
      ref.read(quizGameProvider.notifier).showFeedback(isCorrect);

      // 延迟后提交答案并隐藏反馈
      feedbackTimer = Timer(const Duration(milliseconds: 800), () {
        if (!mounted) return;

        // 隐藏反馈(选中状态会在题目索引变化时自动清除)
        ref.read(quizGameProvider.notifier).hideFeedback();

        // 提交答案到服务(会触发题目索引更新,自动清除选中状态)
        if (isHost) {
          hostService!.gameController.submitAnswer('host', originalIndices);
        } else {
          clientService!.submitAnswer(originalIndices);
        }
      });
    });
  }

  void disposeFeedbackTimer() {
    feedbackTimer?.cancel();
  }
}
