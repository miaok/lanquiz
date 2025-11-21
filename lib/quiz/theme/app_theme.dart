import 'package:flutter/material.dart';

/// Material Design 3 主题配置
class AppTheme {
  // 防止实例化
  AppTheme._();

  // ============ 色彩方案 ============

  /// 浅色主题色彩方案
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    // 主要色彩 - 深绿色系,用于主要组件和高优先级操作
    primary: Color(0xFF255E40), // 深绿色 - 主题色
    onPrimary: Color(0xFFFFFFFF), // 主要色彩上的文字/图标 - 白色
    primaryContainer: Color(0xFFA8DAC1), // 浅绿色容器 - 柔和的绿色背景
    onPrimaryContainer: Color(0xFF002110), // 主要色彩容器上的文字 - 深绿黑色
    // 次要色彩 - 琥珀金色系,用于次要组件和中等优先级操作
    secondary: Color(0xFFFF8F00), // 琥珀金色 - 暖色调对比
    onSecondary: Color(0xFFFFFFFF), // 次要色彩上的文字 - 白色
    secondaryContainer: Color(0xFFFFE0B2), // 浅琥珀色容器
    onSecondaryContainer: Color(0xFF4A2800), // 次要色彩容器上的文字 - 深棕色
    // 第三色彩 - 青蓝色系,用于对比和强调
    tertiary: Color(0xFF0288D1), // 青蓝色 - 冷色调补充
    onTertiary: Color(0xFFFFFFFF), // 第三色彩上的文字 - 白色
    tertiaryContainer: Color(0xFFB3E5FC), // 浅青蓝色容器
    onTertiaryContainer: Color(0xFF01579B), // 第三色彩容器上的文字 - 深蓝色
    // 错误色彩 - 红色系
    error: Color(0xFFD32F2F), // 错误红色
    onError: Color(0xFFFFFFFF), // 错误色上的文字 - 白色
    errorContainer: Color(0xFFFFCDD2), // 浅红色容器
    onErrorContainer: Color(0xFFB71C1C), // 错误容器上的文字 - 深红色
    // 背景色彩 - 中性色系
    surface: Color(0xFFFBFDF9), // 表面 - 微绿色调的白色
    onSurface: Color(0xFF191C1A), // 表面上的文字 - 深灰绿色
    surfaceContainerHighest: Color(0xFFE0E3E0), // 最高表面容器(卡片等) - 浅灰绿色
    onSurfaceVariant: Color(0xFF404943), // 表面变体上的文字 - 中灰绿色
    // 轮廓色彩
    outline: Color(0xFF70796F), // 轮廓线 - 中灰绿色
    outlineVariant: Color(0xFFC0C9BE), // 轮廓变体 - 浅灰绿色
    // 其他
    shadow: Color(0xFF000000), // 阴影 - 黑色
    scrim: Color(0xFF000000), // 遮罩 - 黑色
    inverseSurface: Color(0xFF2E312E), // 反转表面 - 深灰绿色
    onInverseSurface: Color(0xFFF0F1ED), // 反转表面上的文字 - 浅灰色
    inversePrimary: Color(0xFF8DBE9F), // 反转主色 - 亮绿色
  );

  /// 深色主题色彩方案
  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    // 主要色彩 - 亮绿色系,在深色背景上更醒目
    primary: Color(0xFF8DBE9F), // 亮绿色 - 深色模式主色
    onPrimary: Color(0xFF003920), // 主要色彩上的文字 - 深绿色
    primaryContainer: Color(0xFF00522E), // 深绿色容器
    onPrimaryContainer: Color(0xFFA8DAC1), // 主要色彩容器上的文字 - 浅绿色
    // 次要色彩 - 亮琥珀金色系
    secondary: Color(0xFFFFB74D), // 亮琥珀金色 - 深色模式次要色
    onSecondary: Color(0xFF3E2723), // 次要色彩上的文字 - 深棕色
    secondaryContainer: Color(0xFFE65100), // 深琥珀色容器
    onSecondaryContainer: Color(0xFFFFE0B2), // 次要色彩容器上的文字 - 浅琥珀色
    // 第三色彩 - 亮青蓝色系
    tertiary: Color(0xFF4FC3F7), // 亮青蓝色 - 深色模式第三色
    onTertiary: Color(0xFF003C5A), // 第三色彩上的文字 - 深蓝色
    tertiaryContainer: Color(0xFF006494), // 深青蓝色容器
    onTertiaryContainer: Color(0xFFB3E5FC), // 第三色彩容器上的文字 - 浅青蓝色
    // 错误色彩 - 亮红色系
    error: Color(0xFFEF5350), // 亮错误红色
    onError: Color(0xFF601410), // 错误色上的文字 - 深红色
    errorContainer: Color(0xFFC62828), // 深红色容器
    onErrorContainer: Color(0xFFFFDAD6), // 错误容器上的文字 - 浅红色
    // 背景色彩 - 深色中性色系
    surface: Color(0xFF191C1A), // 表面 - 深灰绿色背景
    onSurface: Color(0xFFE0E3E0), // 表面上的文字 - 浅灰绿色
    surfaceContainerHighest: Color(0xFF2E312E), // 最高表面容器(卡片等) - 中灰绿色
    onSurfaceVariant: Color(0xFFC0C9BE), // 表面变体上的文字 - 浅灰绿色
    // 轮廓色彩
    outline: Color(0xFF8A938A), // 轮廓线 - 中灰绿色
    outlineVariant: Color(0xFF404943), // 轮廓变体 - 深灰绿色
    // 其他
    shadow: Color(0xFF000000), // 阴影 - 黑色
    scrim: Color(0xFF000000), // 遮罩 - 黑色
    inverseSurface: Color(0xFFE0E3E0), // 反转表面 - 浅灰绿色
    onInverseSurface: Color(0xFF191C1A), // 反转表面上的文字 - 深灰绿色
    inversePrimary: Color(0xFF255E40), // 反转主色 - 深绿色
  );

  // ============ 排版系统 ============

  /// 文字主题
  static const TextTheme _textTheme = TextTheme(
    // Display - 超大标题
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      height: 1.12,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.16,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.22,
    ),

    // Headline - 标题
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.29,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.33,
    ),

    // Title - 小标题
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      height: 1.27,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      height: 1.5,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),

    // Body - 正文
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.43,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.33,
    ),

    // Label - 标签
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.33,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.45,
    ),
  );

  // ============ 主题数据 ============

  /// 浅色主题
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      textTheme: _textTheme,

      // AppBar 主题
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 3,
        backgroundColor: _lightColorScheme.surface,
        foregroundColor: _lightColorScheme.onSurface,
        surfaceTintColor: _lightColorScheme.primary,
        shadowColor: _lightColorScheme.shadow,
      ),

      // Card 主题
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: _lightColorScheme.shadow.withValues(alpha: 0.15),
        surfaceTintColor: _lightColorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
      ),

      // ElevatedButton 主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          shadowColor: _lightColorScheme.shadow.withValues(alpha: 0.15),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // FilledButton 主题 (MD3新增)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // OutlinedButton 主题
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          side: BorderSide(color: _lightColorScheme.outline, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // TextButton 主题
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // InputDecoration 主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightColorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _lightColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _lightColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _lightColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _lightColorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Chip 主题
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),

      // Dialog 主题
      dialogTheme: DialogThemeData(
        elevation: 3,
        shadowColor: _lightColorScheme.shadow.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),

      // SnackBar 主题
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // FloatingActionButton 主题
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // NavigationBar 主题 (MD3)
      navigationBarTheme: NavigationBarThemeData(
        elevation: 3,
        height: 80,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Divider 主题
      dividerTheme: DividerThemeData(
        color: _lightColorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// 深色主题
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkColorScheme,
      textTheme: _textTheme,

      // AppBar 主题
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 3,
        backgroundColor: _darkColorScheme.surface,
        foregroundColor: _darkColorScheme.onSurface,
        surfaceTintColor: _darkColorScheme.primary,
        shadowColor: _darkColorScheme.shadow,
      ),

      // Card 主题
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: _darkColorScheme.shadow.withValues(alpha: 0.3),
        surfaceTintColor: _darkColorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
      ),

      // ElevatedButton 主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          shadowColor: _darkColorScheme.shadow.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // FilledButton 主题
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // OutlinedButton 主题
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          side: BorderSide(color: _darkColorScheme.outline, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // TextButton 主题
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // InputDecoration 主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkColorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _darkColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _darkColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _darkColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _darkColorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Chip 主题
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),

      // Dialog 主题
      dialogTheme: DialogThemeData(
        elevation: 3,
        shadowColor: _darkColorScheme.shadow.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),

      // SnackBar 主题
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // FloatingActionButton 主题
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // NavigationBar 主题
      navigationBarTheme: NavigationBarThemeData(
        elevation: 3,
        height: 80,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Divider 主题
      dividerTheme: DividerThemeData(
        color: _darkColorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
