import 'package:flutter/material.dart';
import '../../../models/question_model.dart';

/// 选项按钮组件
/// 根据题型(单选/判断/多选)渲染不同样式的选项
class OptionButton extends StatefulWidget {
  final Question question;
  final int index;
  final bool hasAnswered;
  final int? selectedAnswer;
  final List<int> selectedAnswers;
  final VoidCallback onSelectSingle;
  final VoidCallback onToggleMultiple;
  final bool hasSubmittedAnswer; // 是否已提交答案
  final bool submittedAnswerCorrect; // 提交的答案是否正确

  const OptionButton({
    super.key,
    required this.question,
    required this.index,
    required this.hasAnswered,
    this.selectedAnswer,
    this.selectedAnswers = const [],
    required this.onSelectSingle,
    required this.onToggleMultiple,
    this.hasSubmittedAnswer = false,
    this.submittedAnswerCorrect = false,
  });

  @override
  State<OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends State<OptionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void didUpdateWidget(OptionButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 当提交答案状态变化时,触发动画
    if (!oldWidget.hasSubmittedAnswer && widget.hasSubmittedAnswer) {
      final isSelected = _isSelected();

      if (isSelected && !widget.submittedAnswerCorrect) {
        // 只在答错时播放抖动动画
        _playWrongAnimation();
      }
    }
  }

  bool _isSelected() {
    if (widget.question.type == QuestionType.multipleChoice) {
      return widget.selectedAnswers.contains(widget.index);
    } else {
      return widget.selectedAnswer == widget.index;
    }
  }

  // 答错动画:左右抖动
  void _playWrongAnimation() {
    _slideAnimation =
        TweenSequence<Offset>([
          TweenSequenceItem(
            tween: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(0.02, 0),
            ),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween<Offset>(
              begin: const Offset(0.02, 0),
              end: const Offset(-0.02, 0),
            ),
            weight: 2,
          ),
          TweenSequenceItem(
            tween: Tween<Offset>(
              begin: const Offset(-0.02, 0),
              end: const Offset(0.01, 0),
            ),
            weight: 2,
          ),
          TweenSequenceItem(
            tween: Tween<Offset>(
              begin: const Offset(0.01, 0),
              end: Offset.zero,
            ),
            weight: 1,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _animationController.forward().then((_) {
      if (mounted) {
        _animationController.reset();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 根据题型渲染不同的按钮
    switch (widget.question.type) {
      case QuestionType.singleChoice:
      case QuestionType.trueFalse:
        return _buildSingleChoiceOption();
      case QuestionType.multipleChoice:
        return _buildMultipleChoiceOption();
    }
  }

  // 单选题/判断题选项
  Widget _buildSingleChoiceOption() {
    final isSelected = widget.selectedAnswer == widget.index;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: _buildOptionContent(
            isSelected: isSelected,
            isMultipleChoice: false,
          ),
        );
      },
    );
  }

  // 多选题选项
  Widget _buildMultipleChoiceOption() {
    final isSelected = widget.selectedAnswers.contains(widget.index);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: _buildOptionContent(
            isSelected: isSelected,
            isMultipleChoice: true,
          ),
        );
      },
    );
  }

  // 构建选项内容
  Widget _buildOptionContent({
    required bool isSelected,
    required bool isMultipleChoice,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        Color? backgroundColor;
        Color? borderColor;
        Color? textColor;
        Widget? trailingIcon;

        if (widget.hasSubmittedAnswer) {
          // 已提交答案,显示反馈
          if (isSelected) {
            // 用户选择的选项
            if (widget.submittedAnswerCorrect) {
              // 答对了
              backgroundColor = colorScheme.primaryContainer;
              borderColor = colorScheme.primary;
              textColor = colorScheme.onPrimaryContainer;
              trailingIcon = Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 28,
              );
            } else {
              // 答错了
              backgroundColor = colorScheme.errorContainer;
              borderColor = colorScheme.error;
              textColor = colorScheme.onErrorContainer;
              trailingIcon = Icon(
                Icons.cancel,
                color: colorScheme.error,
                size: 28,
              );
            }
          } else {
            // 其他选项 - 不显示正确答案提示
            textColor = colorScheme.onSurface.withValues(alpha: 0.5);
          }
        } else if (isSelected) {
          // 已选择但未提交
          backgroundColor = colorScheme.primary;
          borderColor = colorScheme.primary;
          textColor = colorScheme.onPrimary;
        } else {
          textColor = colorScheme.onSurface;
        }

        return Padding(
          padding: EdgeInsets.only(bottom: isMultipleChoice ? 12 : 18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            transform: isSelected && !widget.hasSubmittedAnswer
                ? (Matrix4.identity()..setTranslationRaw(0.0, 2.0, 0.0))
                : Matrix4.identity(),
            child: OutlinedButton(
              onPressed:
                  widget.hasAnswered ||
                      widget.hasSubmittedAnswer ||
                      (isSelected && !isMultipleChoice)
                  ? null
                  : (isMultipleChoice
                        ? widget.onToggleMultiple
                        : widget.onSelectSingle),
              style: OutlinedButton.styleFrom(
                backgroundColor: backgroundColor,
                side: BorderSide(
                  color: borderColor ?? colorScheme.outline,
                  width: 2,
                ),
                padding: const EdgeInsets.all(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question.options[widget.index],
                      style:
                          (isMultipleChoice
                                  ? textTheme.bodyMedium
                                  : textTheme.bodyLarge)
                              ?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 12),
                    trailingIcon,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
