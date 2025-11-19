import 'package:flutter/material.dart';
import '../../models/quiz_room.dart';
import '../../models/player.dart';

/// 简化的玩家得分榜组件
class PlayerScoreBoard extends StatefulWidget {
  final List<QuizPlayer> players;
  final String myPlayerId;
  final String hostId;
  final RoomStatus roomStatus;
  final int totalQuestions;

  const PlayerScoreBoard({
    super.key,
    required this.players,
    required this.myPlayerId,
    required this.hostId,
    required this.roomStatus,
    required this.totalQuestions,
  });

  @override
  State<PlayerScoreBoard> createState() => _PlayerScoreBoardState();
}

class _PlayerScoreBoardState extends State<PlayerScoreBoard> {
  // 用于追踪每个玩家的上一次答题结果,以触发动画
  final Map<String, AnswerResult> _previousAnswerResults = {};

  @override
  Widget build(BuildContext context) {
    // 找到房主和客户端玩家
    final hostPlayer = widget.players.firstWhere(
      (p) => p.id == widget.hostId,
      orElse: () => widget.players.isNotEmpty
          ? widget.players.first
          : QuizPlayer(id: 'temp', name: 'Host'),
    );

    final clientPlayer = widget.players.firstWhere(
      (p) => p.id != widget.hostId,
      orElse: () => widget.players.length > 1 ? widget.players[1] : hostPlayer,
    );

    final hasClient = widget.players.any((p) => p.id != widget.hostId);

    // 计算最高分，用于进度条归一化
    final maxScore = widget.players.isNotEmpty
        ? widget.players.map((p) => p.score).reduce((a, b) => a > b ? a : b)
        : 100;
    // 避免除以0
    final effectiveMaxScore = maxScore > 0 ? maxScore : 100;

    return Container(
      height: 80,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 左半区域：得分 (从左到右)
          Expanded(
            child: Column(
              children: [
                // 上方：主机端得分
                Expanded(
                  child: _AnimatedMetricBar(
                    key: ValueKey('host_score_${hostPlayer.id}'),
                    player: hostPlayer,
                    shouldAnimate: _shouldAnimate(hostPlayer),
                    currentValue: hostPlayer.score,
                    maxValue: effectiveMaxScore,
                    isScore: true,
                    isReversed: false, // 从左到右
                    label: '${hostPlayer.name}: ${hostPlayer.score}',
                  ),
                ),
                const SizedBox(height: 4),
                // 下方：客户端得分
                Expanded(
                  child: hasClient
                      ? _AnimatedMetricBar(
                          key: ValueKey('client_score_${clientPlayer.id}'),
                          player: clientPlayer,
                          shouldAnimate: _shouldAnimate(clientPlayer),
                          currentValue: clientPlayer.score,
                          maxValue: effectiveMaxScore,
                          isScore: true,
                          isReversed: false, // 从左到右
                          label: '${clientPlayer.name}: ${clientPlayer.score}',
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16), // 中间间距
          // 右半区域：进度 (从右到左)
          Expanded(
            child: Column(
              children: [
                // 上方：主机端进度
                Expanded(
                  child: _AnimatedMetricBar(
                    key: ValueKey('host_progress_${hostPlayer.id}'),
                    player: hostPlayer,
                    shouldAnimate: _shouldAnimate(hostPlayer),
                    currentValue: hostPlayer.isFinished
                        ? widget.totalQuestions
                        : hostPlayer.currentQuestionIndex,
                    maxValue: widget.totalQuestions,
                    isScore: false,
                    isReversed: true, // 从右到左
                    label:
                        '${hostPlayer.isFinished ? widget.totalQuestions : hostPlayer.currentQuestionIndex}/${widget.totalQuestions}',
                  ),
                ),
                const SizedBox(height: 4),
                // 下方：客户端进度
                Expanded(
                  child: hasClient
                      ? _AnimatedMetricBar(
                          key: ValueKey('client_progress_${clientPlayer.id}'),
                          player: clientPlayer,
                          shouldAnimate: _shouldAnimate(clientPlayer),
                          currentValue: clientPlayer.isFinished
                              ? widget.totalQuestions
                              : clientPlayer.currentQuestionIndex,
                          maxValue: widget.totalQuestions,
                          isScore: false,
                          isReversed: true, // 从右到左
                          label:
                              '${clientPlayer.isFinished ? widget.totalQuestions : clientPlayer.currentQuestionIndex}/${widget.totalQuestions}',
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldAnimate(QuizPlayer player) {
    final previous = _previousAnswerResults[player.id];
    final current = player.lastAnswerResult;

    // 更新缓存
    _previousAnswerResults[player.id] = current;

    // 如果从none变为correct或incorrect,触发动画
    return previous != current && current != AnswerResult.none;
  }
}

/// 带有动画效果的单个指标条 (得分或进度)
class _AnimatedMetricBar extends StatefulWidget {
  final QuizPlayer player;
  final bool shouldAnimate;
  final int currentValue;
  final int maxValue;
  final bool isScore;
  final bool isReversed;
  final String label;

  const _AnimatedMetricBar({
    super.key,
    required this.player,
    required this.shouldAnimate,
    required this.currentValue,
    required this.maxValue,
    required this.isScore,
    required this.isReversed,
    required this.label,
  });

  @override
  State<_AnimatedMetricBar> createState() => _AnimatedMetricBarState();
}

class _AnimatedMetricBarState extends State<_AnimatedMetricBar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _answerController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 持续的呼吸动画
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 答题反馈动画
    final duration = _getAnimationDuration();
    _answerController = AnimationController(duration: duration, vsync: this);

    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _answerController, curve: Curves.easeInOut),
        );
  }

  @override
  void didUpdateWidget(_AnimatedMetricBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.shouldAnimate &&
        widget.player.lastAnswerResult != AnswerResult.none) {
      final newDuration = _getAnimationDuration();
      if (_answerController.duration != newDuration) {
        _answerController.duration = newDuration;
      }
      _triggerAnswerAnimation(widget.player.lastAnswerResult);
    }
  }

  Duration _getAnimationDuration() {
    final combo = widget.player.comboCount;
    if (combo >= 6) {
      return const Duration(milliseconds: 300);
    } else if (combo >= 4) {
      return const Duration(milliseconds: 500);
    } else if (combo >= 2) {
      return const Duration(milliseconds: 700);
    } else {
      return const Duration(milliseconds: 1000);
    }
  }

  void _triggerAnswerAnimation(AnswerResult result) {
    _answerController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = widget.player.lastAnswerResult == AnswerResult.correct;
    final isIncorrect =
        widget.player.lastAnswerResult == AnswerResult.incorrect;

    // 计算进度
    final progress = widget.maxValue > 0
        ? widget.currentValue / widget.maxValue
        : 0.0;

    // 获取颜色
    final color = _getProgressColor(isCorrect, isIncorrect, widget.isScore);

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
      builder: (context, child) {
        final scale = _answerController.isAnimating
            ? _scaleAnimation.value
            : _pulseAnimation.value;

        return Transform.scale(
          scale: scale,
          child: _MirroredProgressBar(
            progress: progress,
            color: color,
            height: double.infinity, // 填满父容器
            animate: true,
            duration: _getAnimationDuration(),
            isReversed: widget.isReversed,
            label: widget.label,
          ),
        );
      },
    );
  }

  Color _getProgressColor(bool isCorrect, bool isIncorrect, bool isScore) {
    if (isScore) {
      // 得分进度条：金色系
      if (isCorrect && _answerController.isAnimating) {
        return const Color(0xFFFFD700); // 金色
      } else if (isIncorrect && _answerController.isAnimating) {
        return const Color(0xFF6B7280); // 灰色
      } else {
        return const Color(0xFFFFA500); // 橙色
      }
    } else {
      // 题目进度条:蓝绿色系
      if (isCorrect && _answerController.isAnimating) {
        return const Color(0xFF4ADE80); // 绿色
      } else if (isIncorrect && _answerController.isAnimating) {
        return const Color(0xFFEF4444); // 红色
      } else {
        return const Color(0xFF06B6D4); // 青色
      }
    }
  }
}

/// 镜像对称进度条组件
class _MirroredProgressBar extends StatefulWidget {
  final double progress;
  final Color color;
  final double height;
  final bool animate;
  final Duration? duration;
  final bool isReversed; // true for right-to-left, false for left-to-right
  final String? label;

  const _MirroredProgressBar({
    //super.key,
    required this.progress,
    required this.color,
    required this.height,
    required this.animate,
    this.duration,
    required this.isReversed,
    this.label,
  });

  @override
  State<_MirroredProgressBar> createState() => _MirroredProgressBarState();
}

class _MirroredProgressBarState extends State<_MirroredProgressBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    if (widget.animate) {
      _animationController = AnimationController(
        duration: widget.duration ?? const Duration(milliseconds: 800),
        vsync: this,
      );

      _progressAnimation = Tween<double>(begin: 0.0, end: widget.progress)
          .animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutQuart,
            ),
          );

      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(_MirroredProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.animate && widget.progress != oldWidget.progress) {
      if (widget.duration != oldWidget.duration) {
        _animationController.dispose();
        _animationController = AnimationController(
          duration: widget.duration ?? const Duration(milliseconds: 800),
          vsync: this,
        );
      }

      _progressAnimation =
          Tween<double>(
            begin: _animationController.value * oldWidget.progress,
            end: widget.progress,
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutQuart,
            ),
          );

      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    if (widget.animate) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentProgress = widget.animate
        ? _progressAnimation.value
        : widget.progress;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8), // 稍微圆角
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: widget.isReversed
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: currentProgress.clamp(0.0, 1.0),
                  heightFactor: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.label != null)
              Positioned.fill(
                child: Center(
                  child: Text(
                    widget.label!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(73, 170, 166, 166),
                      shadows: [
                        Shadow(
                          //offset: Offset(0, 1),
                          blurRadius: 1,
                          color: Color.fromARGB(247, 0, 0, 0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
