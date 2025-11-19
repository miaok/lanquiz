import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/quiz_room.dart';
import '../models/player.dart';
import 'quiz_network_service.dart';

/// 客户端服务（玩家）
class QuizClientService {
  final QuizNetworkService _networkService = QuizNetworkService.instance;

  RawDatagramSocket? _udp;
  Socket? _tcp;
  StreamSubscription<String>? _tcpSub;

  final StreamController<QuizRoom> _roomUpdateController =
      StreamController.broadcast();
  final StreamController<String> _statusController =
      StreamController.broadcast();

  Stream<QuizRoom> get roomUpdates => _roomUpdateController.stream;
  Stream<String> get statusUpdates => _statusController.stream;

  QuizRoom? currentRoom;
  String? myPlayerId;

  /// 发现并连接到主机
  Future<bool> discoverAndConnect(QuizPlayer player) async {
    try {
      myPlayerId = player.id;
      _updateStatus('正在搜索房间...');

      // 发现主机
      final host = await _discoverHost(timeout: const Duration(seconds: 10));
      if (host == null) {
        _updateStatus('未找到房间');
        return false;
      }

      _updateStatus('连接到房间: ${host.$3}');

      // 连接到主机
      _tcp = await Socket.connect(
        host.$1,
        host.$2,
        timeout: const Duration(seconds: 5),
      );

      // 发送加入请求
      final joinMessage = NetworkMessage(
        type: MessageType.playerJoin,
        data: player.toJson(),
      );
      _networkService.sendMessage(_tcp!, joinMessage);

      // 监听消息
      _tcpSub = _networkService
          .socketLines(_tcp!)
          .listen(
            _handleServerMessage,
            onDone: () => _updateStatus('已断开连接'),
            onError: (error) => _updateStatus('连接错误: $error'),
          );

      _updateStatus('已连接');
      return true;
    } catch (e) {
      _updateStatus('连接失败: $e');
      return false;
    }
  }

  /// 发现主机
  Future<(String, int, String)?> _discoverHost({
    required Duration timeout,
  }) async {
    final completer = Completer<(String, int, String)?>();

    _udp = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      QuizNetworkService.udpPort,
    );
    _udp!.broadcastEnabled = true;

    late Timer timer;
    timer = Timer(timeout, () {
      _udp?.close();
      if (!completer.isCompleted) completer.complete(null);
    });

    _udp!.listen((event) {
      if (event == RawSocketEvent.read) {
        final dg = _udp!.receive();
        if (dg == null) return;

        final msg = utf8.decode(dg.data);
        if (msg.startsWith(QuizNetworkService.udpTag)) {
          final parts = msg.split(':');
          if (parts.length == 4) {
            final ip = parts[1];
            final port = int.tryParse(parts[2]) ?? QuizNetworkService.tcpPort;
            final roomName = parts[3];

            timer.cancel();
            _udp?.close();
            if (!completer.isCompleted) {
              completer.complete((ip, port, roomName));
            }
          }
        }
      }
    });

    return completer.future;
  }

  /// 处理服务器消息
  void _handleServerMessage(String line) {
    try {
      print(
        '客户端收到消息: ${line.substring(0, line.length > 100 ? 100 : line.length)}...',
      );
      final message = NetworkMessage.fromJson(line);
      print('消息类型: ${message.type}');

      switch (message.type) {
        case MessageType.roomUpdate:
          currentRoom = QuizRoom.fromJson(message.data);
          print(
            '房间状态更新 - 状态: ${currentRoom!.status}, 题目: ${currentRoom!.currentQuestionIndex}, 玩家数: ${currentRoom!.players.length}',
          );
          _roomUpdateController.add(currentRoom!);
          break;

        case MessageType.startGame:
        case MessageType.showAnswer:
        case MessageType.nextQuestion:
          // 这些消息通过roomUpdate处理
          print('收到专用消息类型: ${message.type}');
          break;

        default:
          print('未知消息类型: ${message.type}');
          break;
      }
    } catch (e) {
      print('处理服务器消息失败: $e');
      print('错误消息内容: $line');
    }
  }

  /// 玩家准备
  void playerReady(bool isReady) {
    if (_tcp == null || myPlayerId == null) {
      print('无法发送准备状态：Socket或玩家ID为空');
      return;
    }

    try {
      final message = NetworkMessage(
        type: MessageType.playerReady,
        data: {'playerId': myPlayerId, 'isReady': isReady},
      );
      _networkService.sendMessage(_tcp!, message);
    } catch (e) {
      print('发送准备状态失败: $e');
    }
  }

  /// 提交答案
  void submitAnswer(dynamic answerIndex) {
    if (_tcp == null || myPlayerId == null) {
      print('无法提交答案：Socket或玩家ID为空');
      return;
    }

    try {
      final message = NetworkMessage(
        type: MessageType.playerAnswer,
        data: {'playerId': myPlayerId, 'answerIndex': answerIndex},
      );
      _networkService.sendMessage(_tcp!, message);
    } catch (e) {
      print('提交答案失败: $e');
    }
  }

  void _updateStatus(String status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  /// 断开连接
  void dispose() {
    print('客户端服务正在关闭...');

    // 先取消TCP订阅，停止接收新消息
    _tcpSub?.cancel();

    // 关闭Socket连接
    _tcp?.destroy();
    _udp?.close();

    // 最后关闭stream controller
    if (!_roomUpdateController.isClosed) {
      _roomUpdateController.close();
    }
    if (!_statusController.isClosed) {
      _statusController.close();
    }

    print('客户端服务已关闭');
  }
}
