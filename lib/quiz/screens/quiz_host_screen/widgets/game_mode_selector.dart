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
          children: [
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
          ],
        ),
      ),
    );
  }
}
