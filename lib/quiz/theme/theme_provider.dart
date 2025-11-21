import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 主题模式枚举
enum AppThemeMode {
  /// 浅色模式
  light,

  /// 深色模式
  dark,

  /// 跟随系统
  system,
}

/// 主题状态管理器
///
/// 使用 ChangeNotifier 管理应用主题状态，支持：
/// - 浅色/深色主题切换
/// - 跟随系统主题
/// - 主题模式持久化（可扩展）
class ThemeProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.system;

  /// 获取当前主题模式
  AppThemeMode get themeMode => _themeMode;

  /// 获取系统的亮度
  Brightness get _systemBrightness {
    return SchedulerBinding.instance.platformDispatcher.platformBrightness;
  }

  /// 获取实际应用的主题模式（解析 system 模式）
  ThemeMode get effectiveThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// 判断当前是否为深色模式
  bool get isDarkMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.system:
        return _systemBrightness == Brightness.dark;
    }
  }

  /// 设置主题模式
  ///
  /// [mode] 新的主题模式
  void setThemeMode(AppThemeMode mode) {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();
  }

  /// 切换浅色/深色模式（不包括系统模式）
  void toggleTheme() {
    if (_themeMode == AppThemeMode.light) {
      setThemeMode(AppThemeMode.dark);
    } else {
      setThemeMode(AppThemeMode.light);
    }
  }

  /// 设置为浅色模式
  void setLightMode() {
    setThemeMode(AppThemeMode.light);
  }

  /// 设置为深色模式
  void setDarkMode() {
    setThemeMode(AppThemeMode.dark);
  }

  /// 设置为跟随系统
  void setSystemMode() {
    setThemeMode(AppThemeMode.system);
  }
}
