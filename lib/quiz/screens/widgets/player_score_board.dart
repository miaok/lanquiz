import 'package:flutter/material.dart';
import '../../models/quiz_room.dart';
import '../../models/player.dart';

/// 对抗式玩家得分榜组件
class PlayerScoreBoard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // 找到房主和客户端玩家
    final hostPlayer = players.firstWhere(
      (p) => p.id == hostId,
      orElse: () => players.isNotEmpty
          ? players.first
          : QuizPlayer(id: 'temp', name: 'Host'),
    );

    final clientPlayer = players.firstWhere(
      (p) => p.id != hostId,
      orElse: () => players.length > 1 ? players[1] : hostPlayer,
    );

    final hasClient = players.any((p) => p.id != hostId);

    return Container(
      height: 80,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // 上方：得分对抗条
          Expanded(
            child: _VersusBar(
              player1Name: hostPlayer.name,
              player1Value: hostPlayer.score,
              player2Name: hasClient ? clientPlayer.name : '',
              player2Value: hasClient ? clientPlayer.score : 0,
              isScore: true,
              hasOpponent: hasClient,
            ),
          ),
          const SizedBox(height: 8),
          // 下方：进度对抗条
          Expanded(
            child: _VersusBar(
              player1Name: hostPlayer.name,
              player1Value: hostPlayer.isFinished
                  ? totalQuestions
                  : hostPlayer.currentQuestionIndex,
              player2Name: hasClient ? clientPlayer.name : '',
              player2Value: hasClient
                  ? (clientPlayer.isFinished
                        ? totalQuestions
                        : clientPlayer.currentQuestionIndex)
                  : 0,
              isScore: false,
              hasOpponent: hasClient,
              maxValue: totalQuestions,
            ),
          ),
        ],
      ),
    );
  }
}

/// 对抗式进度条组件（两个玩家从两端推进）
class _VersusBar extends StatelessWidget {
  final String player1Name;
  final int player1Value;
  final String player2Name;
  final int player2Value;
  final bool isScore;
  final bool hasOpponent;
  final int? maxValue; // 用于进度条的最大值

  const _VersusBar({
    required this.player1Name,
    required this.player1Value,
    required this.player2Name,
    required this.player2Value,
    required this.isScore,
    required this.hasOpponent,
    this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 计算两个玩家的占比
    final total = player1Value + player2Value;
    final player1Ratio = total > 0 ? player1Value / total : 0.5;
    final player2Ratio = total > 0 ? player2Value / total : 0.5;

    // 如果没有对手，玩家1占满整个进度条
    final effectivePlayer1Ratio = hasOpponent ? player1Ratio : 1.0;
    final effectivePlayer2Ratio = hasOpponent ? player2Ratio : 0.0;

    // 获取颜色（基于玩家之间的相对优势）
    // 使用占比作为饱和度的依据
    final player1Color = _getColorByRatio(
      player1Ratio,
      isScore,
      isPlayer1: true,
    );
    final player2Color = _getColorByRatio(
      player2Ratio,
      isScore,
      isPlayer1: false,
    );

    // 生成标签（基于相对优势）
    final player1Label = _getLabelByRatio(
      player1Name,
      player1Value,
      player1Ratio,
      isScore,
      maxValue,
    );
    final player2Label = hasOpponent
        ? _getLabelByRatio(
            player2Name,
            player2Value,
            player2Ratio,
            isScore,
            maxValue,
          )
        : '';

    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // 玩家1的进度条（从左侧开始）
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: effectivePlayer1Ratio.clamp(0.0, 1.0),
                  heightFactor: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: player1Color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 玩家2的进度条（从右侧开始）
            if (hasOpponent)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: effectivePlayer2Ratio.clamp(0.0, 1.0),
                    heightFactor: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: player2Color,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // 玩家1标签（左侧）
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Text(
                  player1Label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getAdaptiveTextColor(player1Color, colorScheme),
                    shadows: [
                      Shadow(
                        blurRadius: 2,
                        color: _getShadowColor(player1Color),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // 玩家2标签（右侧）
            if (hasOpponent)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Text(
                    player2Label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getAdaptiveTextColor(player2Color, colorScheme),
                      shadows: [
                        Shadow(
                          blurRadius: 2,
                          color: _getShadowColor(player2Color),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 根据玩家占比获取颜色 (占比越高饱和度越高)
  Color _getColorByRatio(
    double ratio,
    bool isScore, {
    required bool isPlayer1,
  }) {
    // 占比范围 0.0 ~ 1.0
    // 将占比映射到饱和度：占比50%时饱和度50%，占比越高饱和度越高
    // 使用非线性映射，让优势更明显
    final saturation = 0.2 + (ratio * 0.8); // 20% ~ 100%

    if (isScore) {
      // 得分使用橙色系
      final lightness = 0.55;
      // 玩家1和玩家2使用不同的色相以区分
      final hue = isPlayer1 ? 30.0 : 15.0; // 橙色 vs 橙红色
      return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
    } else {
      // 进度使用蓝色系
      final lightness = 0.50;
      // 玩家1和玩家2使用不同的色相以区分
      final hue = isPlayer1 ? 210.0 : 195.0; // 蓝色 vs 青蓝色
      return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
    }
  }

  /// 根据玩家占比生成标签（占比越高越嚣张）
  String _getLabelByRatio(
    String name,
    int value,
    double ratio,
    bool isScore,
    int? maxValue,
  ) {
    if (isScore) {
      // 得分标签 - 基于相对优势
      if (ratio >= 0.7) {
        // 碾压优势 (70%+)
        return '$value分 ψ(｀∇´)ψ';
      } else if (ratio >= 0.6) {
        // 明显领先 (60%+)
        return '$value分 ( •̀ ω •́ )';
      } else if (ratio >= 0.5) {
        // 恰好相等时显示棋逢对手
        if (ratio == 0.5) {
          return '$value分 ( ͡• ͜ʖ ͡• )';
        } else {
          // 微弱领先 (50%+)
          return '$value分 o(^▽^)o';
        }
      } else if (ratio >= 0.4) {
        // 微弱落后 (40%+)
        return '$value分 〒▽〒';
      } else if (ratio >= 0.3) {
        // 明显落后 (30%+)
        return '$value分 ≧ ﹏ ≦';
      } else {
        // 大幅落后 (<30%)
        return '$value分 X﹏X';
      }
    } else {
      // 进度标签 - 基于相对优势
      //final max = maxValue ?? value;
      if (ratio >= 0.7) {
        // 碾压优势
        return '${value+1}题 ƪ(˘⌣˘)ʃ';
      } else if (ratio >= 0.6) {
        // 明显领先
        return '${value+1}题 （￣︶￣）';
      } else if (ratio >= 0.5) {
        // 恰好相等时显示棋逢对手
        if (ratio == 0.5) {
          return '${value+1}题（⊙ｏ⊙）';
        } else {
          // 微弱领先
          return '${value+1}题 (●ˇ∀ˇ●)';
        }
      } else if (ratio >= 0.4) {
        // 微弱落后
        return '${value+1}题 ( •̀ ω •́ )';
      } else if (ratio >= 0.3) {
        // 明显落后
        return '${value+1}题 ಠ_ಠ';
      } else {
        // 大幅落后
        return '${value+1}题 ಥ_ಥ';
      }
    }
  }

  /// 根据背景色自适应文本颜色
  Color _getAdaptiveTextColor(Color backgroundColor, ColorScheme colorScheme) {
    final luminance = backgroundColor.computeLuminance();

    if (luminance < 0.5) {
      return colorScheme.surface;
    } else {
      return colorScheme.onSurface;
    }
  }

  /// 获取自适应阴影颜色
  Color _getShadowColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();

    if (luminance < 0.5) {
      return Colors.white.withValues(alpha: 0.5);
    } else {
      return Colors.black.withValues(alpha: 0.3);
    }
  }
}
