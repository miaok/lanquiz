import 'package:flutter/material.dart';
import 'screens/quiz_home_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

/// 知识竞答应用入口
class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 ListenableBuilder 监听主题变化
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: '知识竞答',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController.themeMode,
          home: const QuizHomeScreen(),
        );
      },
    );
  }
}

/// 全局主题控制器单例
///
/// 提供全局访问主题管理器的入口
class ThemeController {
  ThemeController._();

  static final ThemeProvider _instance = ThemeProvider();

  /// 获取主题管理器实例
  static ThemeProvider get instance => _instance;

  /// 便捷方法：切换主题
  static void toggleTheme() => _instance.toggleTheme();

  /// 便捷方法：设置浅色模式
  static void setLightMode() => _instance.setLightMode();

  /// 便捷方法：设置深色模式
  static void setDarkMode() => _instance.setDarkMode();

  /// 便捷方法：设置跟随系统
  static void setSystemMode() => _instance.setSystemMode();

  /// 便捷方法：获取当前主题模式
  static ThemeMode get themeMode => _instance.effectiveThemeMode;

  /// 便捷方法：判断是否为深色模式
  static bool get isDarkMode => _instance.isDarkMode;
}
