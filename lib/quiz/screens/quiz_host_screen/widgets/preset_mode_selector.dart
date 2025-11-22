import 'package:flutter/material.dart';

/// 快捷设置模式枚举
enum QuizPresetMode {
  casual, // 娱乐模式
  standard, // 标准模式
  extreme, // 极限模式
}

/// 预设模式选择器组件
class PresetModeSelector extends StatelessWidget {
  final QuizPresetMode? selectedPreset;
  final ValueChanged<QuizPresetMode?> onPresetChanged;

  const PresetModeSelector({
    super.key,
    required this.selectedPreset,
    required this.onPresetChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SegmentedButton<QuizPresetMode>(
        segments: const [
          ButtonSegment<QuizPresetMode>(
            value: QuizPresetMode.casual,
            label: Text('娱乐'),
            icon: Icon(Icons.sentiment_satisfied_alt, size: 18),
          ),
          ButtonSegment<QuizPresetMode>(
            value: QuizPresetMode.standard,
            label: Text('标准'),
            icon: Icon(Icons.star, size: 18),
          ),
          ButtonSegment<QuizPresetMode>(
            value: QuizPresetMode.extreme,
            label: Text('极限'),
            icon: Icon(Icons.local_fire_department, size: 18),
          ),
        ],
        selected: selectedPreset != null ? {selectedPreset!} : {},
        emptySelectionAllowed: true,
        onSelectionChanged: (Set<QuizPresetMode> selected) {
          if (selected.isNotEmpty) {
            onPresetChanged(selected.first);
          }
        },
        style: ButtonStyle(visualDensity: VisualDensity.compact),
      ),
    );
  }
}

/// 预设模式配置
class PresetModeConfig {
  final int trueFalseCount;
  final int singleChoiceCount;
  final int multipleChoiceCount;

  const PresetModeConfig({
    required this.trueFalseCount,
    required this.singleChoiceCount,
    required this.multipleChoiceCount,
  });

  /// 获取预设模式的配置
  static PresetModeConfig getConfig(QuizPresetMode mode) {
    return switch (mode) {
      QuizPresetMode.casual => const PresetModeConfig(
        trueFalseCount: 10,
        singleChoiceCount: 10,
        multipleChoiceCount: 10,
      ),
      QuizPresetMode.standard => const PresetModeConfig(
        trueFalseCount: 34,
        singleChoiceCount: 33,
        multipleChoiceCount: 33,
      ),
      QuizPresetMode.extreme => const PresetModeConfig(
        trueFalseCount: 68,
        singleChoiceCount: 66,
        multipleChoiceCount: 66,
      ),
    };
  }
}
