import 'package:vibration/vibration.dart';
import 'app_logger.dart';

/// 震动反馈工具类
class HapticFeedback {
  /// 检查设备是否支持震动
  static Future<bool> _hasVibrator() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      return hasVibrator == true;
    } catch (e) {
      appLogger.w('检查震动支持失败', e);
      return false;
    }
  }

  /// 轻触震动 - 用于按钮点击
  /// 持续时间: 10ms
  static Future<void> light() async {
    try {
      if (await _hasVibrator()) {
        await Vibration.vibrate(duration: 10);
      }
    } catch (e) {
      appLogger.w('轻触震动失败', e);
    }
  }

  /// 中等震动 - 用于一般操作反馈
  /// 持续时间: 20ms
  static Future<void> medium() async {
    try {
      if (await _hasVibrator()) {
        await Vibration.vibrate(duration: 20);
      }
    } catch (e) {
      appLogger.w('中等震动失败', e);
    }
  }

  /// 成功震动 - 用于答对题目
  /// 模式: 短-停-短 (轻脆感)
  static Future<void> success() async {
    try {
      if (await _hasVibrator()) {
        // 两次短震动，中间间隔50ms
        await Vibration.vibrate(
          pattern: [0, 30, 30, 30],
          intensities: [0, 108, 0, 108],
        );
      }
    } catch (e) {
      appLogger.w('成功震动失败', e);
    }
  }

  /// 错误震动 - 用于答错题目
  /// 模式: 长-停-长-停-长 (强烈感)
  static Future<void> error() async {
    try {
      if (await _hasVibrator()) {
        // 三次震动，逐渐增强
        await Vibration.vibrate(
          pattern: [0, 50, 30, 60, 30, 70],
          intensities: [0, 180, 0, 200, 0, 255],
        );
      }
    } catch (e) {
      appLogger.w('错误震动失败', e);
    }
  }

  /// 重震动 - 用于重要提示
  /// 持续时间: 50ms
  static Future<void> heavy() async {
    try {
      if (await _hasVibrator()) {
        await Vibration.vibrate(duration: 50);
      }
    } catch (e) {
      appLogger.w('重震动失败', e);
    }
  }

  /// 连击震动 - 用于连击反馈
  /// 根据连击数调整震动强度
  static Future<void> combo(int comboCount) async {
    try {
      if (await _hasVibrator()) {
        if (comboCount >= 10) {
          // 10连击以上：超强震动
          await Vibration.vibrate(
            pattern: [0, 40, 20, 40, 20, 60],
            intensities: [0, 200, 0, 220, 0, 255],
          );
        } else if (comboCount >= 5) {
          // 5-9连击：强震动
          await Vibration.vibrate(
            pattern: [0, 30, 20, 40],
            intensities: [0, 180, 0, 200],
          );
        } else if (comboCount >= 3) {
          // 3-4连击：中等震动
          await Vibration.vibrate(
            pattern: [0, 25, 15, 30],
            intensities: [0, 150, 0, 170],
          );
        } else {
          // 1-2连击：轻震动
          await success();
        }
      }
    } catch (e) {
      appLogger.w('连击震动失败', e);
    }
  }

  /// 取消所有震动
  static Future<void> cancel() async {
    try {
      await Vibration.cancel();
    } catch (e) {
      appLogger.w('取消震动失败', e);
    }
  }
}
