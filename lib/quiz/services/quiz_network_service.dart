import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

  /// 获取本地IP地址
  Future<String> getLocalIPv4() async {
    final ifaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    for (final ni in ifaces) {
      for (final a in ni.addresses) {
        if (!a.isLoopback && a.type == InternetAddressType.IPv4) {
          return a.address;
        }
      }
    }
    return '192.168.1.1';
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
      print('发送消息失败: $e');
    }
  }

  /// 广播消息给所有客户端
  void broadcastMessage(List<Socket> clients, NetworkMessage message) {
    for (final client in clients) {
      sendMessage(client, message);
    }
  }
}
