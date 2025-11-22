import 'package:flutter/material.dart';
import '../../../models/player.dart';
import '../../../models/quiz_room.dart';
import 'wrong_answer_item.dart';

/// 排行榜项组件
class RankListItem extends StatelessWidget {
  final QuizPlayer player;
  final int rank;
  final QuizRoom room;

  const RankListItem({
    super.key,
    required this.player,
    required this.rank,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (medalColor, medalIcon, rankColor) = _getRankStyle(rank, colorScheme);
    final hasWrongAnswers = player.wrongAnswers.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: rank <= 3 ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          enabled: hasWrongAnswers,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: _buildRankBadge(medalColor, medalIcon, rankColor),
          title: Text(
            player.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
              color: colorScheme.onSurface,
            ),
          ),
          trailing: _buildTrailing(colorScheme, rankColor, hasWrongAnswers),
          children: [
            if (hasWrongAnswers) _buildWrongAnswersSection(colorScheme),
          ],
        ),
      ),
    );
  }

  /// 构建排名徽章
  Widget _buildRankBadge(
    Color medalColor,
    IconData? medalIcon,
    Color rankColor,
  ) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: medalColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: rankColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: medalIcon != null
            ? Icon(medalIcon, color: Colors.white, size: 24)
            : Text(
                '$rank',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
      ),
    );
  }

  /// 构建尾部（分数和展开图标）
  Widget _buildTrailing(
    ColorScheme colorScheme,
    Color rankColor,
    bool hasWrongAnswers,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: rank <= 3 ? rankColor : colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (rank <= 3 ? rankColor : colorScheme.primaryContainer)
                    .withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '${player.score} 分',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: rank <= 3 ? Colors.white : colorScheme.primary,
            ),
          ),
        ),
        if (hasWrongAnswers) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.expand_more, color: colorScheme.error, size: 20),
          ),
        ],
      ],
    );
  }

  /// 构建错题区域
  Widget _buildWrongAnswersSection(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: colorScheme.error, size: 20),
              const SizedBox(width: 8),
              Text(
                '错题回顾',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.error,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...player.wrongAnswers.map((wrongAnswer) {
            final questionId = wrongAnswer['questionId'] as String;
            final question = room.questions.firstWhere(
              (q) => q.id == questionId,
              orElse: () => room.questions.first,
            );
            return WrongAnswerItem(
              wrongAnswer: wrongAnswer,
              question: question,
            );
          }),
        ],
      ),
    );
  }

  /// 获取排名样式
  (Color, IconData?, Color) _getRankStyle(int rank, ColorScheme colorScheme) {
    return switch (rank) {
      1 => (
        const Color(0xFFFFB74D),
        Icons.emoji_events,
        const Color(0xFFFF8F00),
      ),
      2 => (
        const Color(0xFFBDBDBD),
        Icons.emoji_events,
        const Color(0xFF757575),
      ),
      3 => (
        const Color(0xFFBCAAA4),
        Icons.emoji_events,
        const Color(0xFF6D4C41),
      ),
      _ => (colorScheme.primaryContainer, null, colorScheme.primary),
    };
  }
}
