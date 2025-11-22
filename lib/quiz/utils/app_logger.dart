import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// 全局日志工具类
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;

  late final Logger _logger;

  AppLogger._internal() {
    _logger = Logger(
      printer: kDebugMode
          ? PrettyPrinter(
              methodCount: 0, // 不显示方法调用栈
              errorMethodCount: 5, // 错误时显示5层调用栈
              lineLength: 80, // 每行长度
              colors: true, // 使用颜色
              printEmojis: true, // 使用表情符号
              dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
            )
          : SimplePrinter(), // 生产环境使用简单格式
      level: kDebugMode ? Level.debug : Level.warning, // 根据模式设置日志级别
    );
  }

  /// 获取 Logger 实例
  Logger get logger => _logger;

  /// Debug 级别日志
  void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Info 级别日志
  void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Warning 级别日志
  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Error 级别日志
  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Fatal 级别日志
  void f(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}

/// 全局日志实例
final appLogger = AppLogger();
