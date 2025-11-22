import 'package:flutter/material.dart';
import 'question_type_slider.dart';
import 'preset_mode_selector.dart';

/// 题目配置卡片组件
class QuestionConfigCard extends StatelessWidget {
  final int trueFalseCount;
  final int singleChoiceCount;
  final int multipleChoiceCount;
  final QuizPresetMode? selectedPreset;
  final ValueChanged<int> onTrueFalseChanged;
  final ValueChanged<int> onSingleChoiceChanged;
  final ValueChanged<int> onMultipleChoiceChanged;
  final ValueChanged<QuizPresetMode?> onPresetChanged;

  const QuestionConfigCard({
    super.key,
    required this.trueFalseCount,
    required this.singleChoiceCount,
    required this.multipleChoiceCount,
    required this.selectedPreset,
    required this.onTrueFalseChanged,
    required this.onSingleChoiceChanged,
    required this.onMultipleChoiceChanged,
    required this.onPresetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 判断题数量
            QuestionTypeSlider(
              label: '判断题',
              count: trueFalseCount,
              onChanged: onTrueFalseChanged,
              icon: Icons.check_circle_outline,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),

            // 单选题数量
            QuestionTypeSlider(
              label: '单选题',
              count: singleChoiceCount,
              onChanged: onSingleChoiceChanged,
              icon: Icons.radio_button_checked,
              color: colorScheme.secondary,
            ),
            const SizedBox(height: 12),

            // 多选题数量
            QuestionTypeSlider(
              label: '多选题',
              count: multipleChoiceCount,
              onChanged: onMultipleChoiceChanged,
              icon: Icons.checklist,
              color: colorScheme.tertiary,
            ),
            const SizedBox(height: 12),

            // 快捷设置按钮
            PresetModeSelector(
              selectedPreset: selectedPreset,
              onPresetChanged: onPresetChanged,
            ),
          ],
        ),
      ),
    );
  }
}
