import 'package:flutter/material.dart';
import '../quiz_app.dart';
import 'theme_provider.dart';

/// 主题切换组件
///
/// 提供三种主题模式选择：浅色、深色、跟随系统
class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_getThemeIcon()),
      onPressed: () => _showThemeDialog(context),
      tooltip: '切换主题',
    );
  }

  /// 获取当前主题对应的图标
  IconData _getThemeIcon() {
    final themeMode = ThemeController.instance.themeMode;
    switch (themeMode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  /// 显示主题选择对话框
  void _showThemeDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.palette, color: colorScheme.primary),
            const SizedBox(width: 12),
            const Text('选择主题'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeModeOption(
              icon: Icons.light_mode,
              label: '浅色模式',
              description: '使用明亮的配色方案',
              mode: AppThemeMode.light,
            ),
            const SizedBox(height: 8),
            _ThemeModeOption(
              icon: Icons.dark_mode,
              label: '深色模式',
              description: '使用暗色的配色方案',
              mode: AppThemeMode.dark,
            ),
            const SizedBox(height: 8),
            _ThemeModeOption(
              icon: Icons.brightness_auto,
              label: '跟随系统',
              description: '根据系统设置自动切换',
              mode: AppThemeMode.system,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

/// 主题模式选项
class _ThemeModeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final AppThemeMode mode;

  const _ThemeModeOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentMode = ThemeController.instance.themeMode;
    final isSelected = currentMode == mode;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          ThemeController.instance.setThemeMode(mode);
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: colorScheme.primary, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// 简单的主题切换按钮（仅在浅色和深色之间切换）
class SimpleThemeToggle extends StatelessWidget {
  const SimpleThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.isDarkMode;

    return IconButton(
      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
      onPressed: () {
        ThemeController.toggleTheme();
      },
      tooltip: isDark ? '切换到浅色模式' : '切换到深色模式',
    );
  }
}
