import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/quiz_home_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

/// 应用入口
class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 ListenableBuilder 监听主题变化
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        // 根据当前主题模式确定系统UI样式
        final isDark = ThemeController.isDarkMode;

        // 使用具体的颜色值而非透明,提高兼容性
        final systemUiOverlayStyle = SystemUiOverlayStyle(
          // 状态栏配置
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,

          // 系统导航条配置
          // 浅色模式使用浅色背景,深色模式使用深色背景
          systemNavigationBarColor: isDark
              ? const Color(0xFF191C1A) // 深色模式:深灰绿色(与 surface 一致)
              : const Color(0xFFFBFDF9), // 浅色模式:微绿色调的白色(与 surface 一致)
          systemNavigationBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false, // 禁用系统强制对比度(某些魔改系统会强制修改)
        );

        // 使用 AnnotatedRegion 包裹整个应用,确保系统UI样式生效
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: systemUiOverlayStyle,
          child: MaterialApp(
            title: 'LanQuiz',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeController.themeMode,
            home: const QuizHomeScreen(),
          ),
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
