import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../utils/app_logger.dart';

/// 网络消息类型
enum MessageType {
  roomUpdate, // 房间状态更新
  playerJoin, // 玩家加入
  playerReady, // 玩家准备
  startGame, // 开始游戏
  nextQuestion, // 下一题
  playerAnswer, // 玩家答题
  showAnswer, // 显示答案
  gameEnd, // 游戏结束
  heartbeat, // 心跳包
}

/// 网络消息
class NetworkMessage {
  final MessageType type;
  final Map<String, dynamic> data;

  NetworkMessage({required this.type, required this.data});

  String toJson() => jsonEncode({'type': type.name, 'data': data});

  factory NetworkMessage.fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr);
    return NetworkMessage(
      type: MessageType.values.firstWhere((e) => e.name == map['type']),
      data: map['data'],
    );
  }
}

/// 知识竞答网络服务
class QuizNetworkService {
  static const int tcpPort = 4050;
  static const int udpPort = 4055;
  static const String udpTag = 'QUIZ_HOST';

  static final QuizNetworkService instance = QuizNetworkService._init();
  QuizNetworkService._init();

  /// 检查是否连接到WiFi
  Future<bool> isWiFiConnected() async {
    try {
      final ifaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      // 检查是否有WiFi接口（通常名称包含wlan、wifi、en0等）
      for (final ni in ifaces) {
        final name = ni.name.toLowerCase();
        // Android: wlan
        if (name.contains('wlan') ||
            name.contains('wifi') ||
            (name.startsWith('en') && ni.addresses.isNotEmpty)) {
          // 检查是否有有效的局域网IP地址
          for (final addr in ni.addresses) {
            if (!addr.isLoopback && _isLocalNetworkIP(addr.address)) {
              return true;
            }
          }
        }
      }
      return false;
    } catch (e) {
      appLogger.w('Error checking WiFi connection', e);
      return false;
    }
  }

  /// 检查是否是局域网IP地址
  bool _isLocalNetworkIP(String ip) {
    // 检查是否是私有IP地址段
    // 10.0.0.0 - 10.255.255.255
    // 172.16.0.0 - 172.31.255.255
    // 192.168.0.0 - 192.168.255.255
    final parts = ip.split('.');
    if (parts.length != 4) return false;

    final first = int.tryParse(parts[0]) ?? 0;
    final second = int.tryParse(parts[1]) ?? 0;

    return (first == 10) ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 192 && second == 168);
  }

  /// 获取本地WiFi IP地址（只返回WiFi接口的IP）
  Future<String?> getLocalIPv4() async {
    try {
      final ifaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      // 优先查找WiFi接口
      for (final ni in ifaces) {
        final name = ni.name.toLowerCase();
        // 检查是否是WiFi接口
        if (name.contains('wlan') ||
            name.contains('wifi') ||
            name.contains('wi-fi') ||
            (name.startsWith('en') && ni.addresses.isNotEmpty)) {
          for (final addr in ni.addresses) {
            if (!addr.isLoopback &&
                addr.type == InternetAddressType.IPv4 &&
                _isLocalNetworkIP(addr.address)) {
              return addr.address;
            }
          }
        }
      }

      // 如果没有找到WiFi接口，返回null表示未连接WiFi
      return null;
    } catch (e) {
      appLogger.w('Error getting local IPv4', e);
      return null;
    }
  }

  /// Socket扩展：将Socket流转换为字符串行流
  Stream<String> socketLines(Socket socket) {
    return socket
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .transform(const LineSplitter());
  }

  /// 发送消息
  void sendMessage(Socket socket, NetworkMessage message) {
    try {
      socket.write('${message.toJson()}\n');
    } catch (e) {
      throw NetworkException('发送消息失败: $e');
    }
  }

  /// 广播消息给所有客户端
  void broadcastMessage(List<Socket> clients, NetworkMessage message) {
    for (final client in clients) {
      try {
        sendMessage(client, message);
      } catch (e) {
        appLogger.w('Failed to send message to client', e);
        // 忽略单个客户端发送失败
      }
    }
  }

  /// 获取友好的错误信息
  String getFriendlyErrorMessage(dynamic error) {
    final e = error.toString();
    if (e.contains('Connection refused')) {
      return '无法连接到主机，请检查主机IP是否正确或主机是否已开启';
    } else if (e.contains('Network is unreachable')) {
      return '网络不可用，请检查您的网络连接';
    } else if (e.contains('Connection timed out')) {
      return '连接超时，请检查网络状况';
    } else if (e.contains('Connection reset by peer')) {
      return '连接被断开';
    } else if (e.contains('No route to host')) {
      return '无法访问主机，请检查是否在同一局域网内';
    }
    return '网络错误: $error';
  }
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => message;
}
