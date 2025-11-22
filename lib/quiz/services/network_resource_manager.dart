import 'dart:async';
import 'dart:io';
import '../utils/app_logger.dart';

/// 网络资源管理 Mixin
/// 提供统一的资源清理逻辑
mixin NetworkResourceManager {
  /// 安全关闭 StreamController
  Future<void> closeStreamController(StreamController? controller) async {
    if (controller != null && !controller.isClosed) {
      try {
        await controller.close();
      } catch (e) {
        appLogger.w('关闭 StreamController 失败', e);
      }
    }
  }

  /// 安全关闭 Socket
  Future<void> closeSocket(Socket? socket) async {
    if (socket != null) {
      try {
        socket.destroy();
        // 等待连接完全关闭
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        appLogger.w('关闭 Socket 失败', e);
      }
    }
  }

  /// 安全关闭 ServerSocket
  Future<void> closeServerSocket(ServerSocket? server) async {
    if (server != null) {
      try {
        await server.close();
        // 等待端口释放
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        appLogger.w('关闭 ServerSocket 失败', e);
      }
    }
  }

  /// 安全关闭 RawDatagramSocket
  void closeDatagramSocket(RawDatagramSocket? udp) {
    try {
      udp?.close();
    } catch (e) {
      appLogger.w('关闭 RawDatagramSocket 失败', e);
    }
  }

  /// 安全取消 Timer
  void cancelTimer(Timer? timer) {
    timer?.cancel();
  }

  /// 安全取消 StreamSubscription
  Future<void> cancelSubscription(StreamSubscription? subscription) async {
    if (subscription != null) {
      try {
        await subscription.cancel();
      } catch (e) {
        appLogger.w('取消 StreamSubscription 失败', e);
      }
    }
  }

  /// 批量关闭 Sockets
  Future<void> closeSockets(List<Socket> sockets) async {
    for (final socket in sockets.toList()) {
      await closeSocket(socket);
    }
    sockets.clear();
  }
}
