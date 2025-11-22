import 'package:flutter/material.dart';
import '../../../models/quiz_room_model.dart';

class GameModeSelector extends StatelessWidget {
  final GameMode selectedMode;
  final ValueChanged<GameMode> onModeChanged;

  const GameModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sports_esports,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('游戏模式', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<GameMode>(
                segments: const [
                  ButtonSegment(
                    value: GameMode.fast,
                    label: Text('快速模式'),
                    icon: Icon(Icons.speed),
                  ),
                  ButtonSegment(
                    value: GameMode.force,
                    label: Text('强制模式'),
                    icon: Icon(Icons.lock),
                  ),
                ],
                selected: {selectedMode},
                onSelectionChanged: (Set<GameMode> newSelection) {
                  onModeChanged(newSelection.first);
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              selectedMode == GameMode.fast
                  ? '答完即走，不管对错，追求速度'
                  : '必须答对才能进入下一题，追求准确率',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
