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

  StreamController<QuizRoom>? _roomUpdateController;
  StreamController<String>? _statusController;
  StreamController<void>? _disconnectController;

  Stream<QuizRoom> get roomUpdates => _roomUpdateController!.stream;
  Stream<String> get statusUpdates => _statusController!.stream;
  Stream<void> get onDisconnected => _disconnectController!.stream;

  QuizRoom? currentRoom;
  String? myPlayerId;
  String? _myIp; // 缓存本地IP地址

  /// 获取连接的主机IP地址
  String? get hostIp => _tcp?.remoteAddress.address;

  /// 获取本地IP地址
  String? get myIp => _myIp;

  /// 发现并连接到主机
  Future<bool> discoverAndConnect(QuizPlayer player) async {
    try {
      // 先清理可能存在的旧连接
      await _cleanupConnection();

      // 重新创建StreamController(支持服务重用)
      _roomUpdateController = StreamController.broadcast();
      _statusController = StreamController.broadcast();
      _disconnectController = StreamController.broadcast();

      // 检查WiFi连接
      final isWiFi = await _networkService.isWiFiConnected();
      if (!isWiFi) {
        _updateStatus('未连接WiFi，请连接WiFi后重试');
        return false;
      }

      myPlayerId = player.id;
      _updateStatus('正在搜索房间...');

      // 发现主机
      final host = await _discoverHost(timeout: const Duration(seconds: 10));
      if (host == null) {
        _updateStatus('未找到房间');
        return false;
      }

      _updateStatus('连接到房间: ${host.$3}');

      // 连接到主机,添加重试机制
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          _tcp = await Socket.connect(
            host.$1,
            host.$2,
            timeout: const Duration(seconds: 5),
          );

          // 设置Socket选项
          _tcp!.setOption(SocketOption.tcpNoDelay, true);

          // print('成功连接到主机: ${host.$1}:${host.$2}');
          break;
        } catch (e) {
          retryCount++;
          // print('连接失败 (尝试 $retryCount/$maxRetries): $e');

          if (retryCount >= maxRetries) {
            _updateStatus('连接失败: 无法连接到主机');
            return false;
          }

          // 等待后重试
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        }
      }

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
            onDone: () {
              // print('与主机的连接已断开');
              _updateStatus('已断开连接');
              if (_disconnectController != null &&
                  !_disconnectController!.isClosed) {
                _disconnectController!.add(null);
              }
            },
            onError: (error) {
              // print('连接错误: $error');
              _updateStatus('连接错误: $error');
              if (_disconnectController != null &&
                  !_disconnectController!.isClosed) {
                _disconnectController!.add(null);
              }
            },
            cancelOnError: false,
          );

      // 获取本地IP地址
      _myIp = await _networkService.getLocalIPv4();

      _updateStatus('已连接');
      return true;
    } catch (e) {
      // print('连接失败: $e');
      // print('堆栈跟踪: $stackTrace');
      _updateStatus('连接失败: $e');
      await _cleanupConnection();
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
    // try {
    // print(
    //   '客户端收到消息: ${line.substring(0, line.length > 100 ? 100 : line.length)}...',
    // );
    final message = NetworkMessage.fromJson(line);
    //print('消息类型: ${message.type}');

    switch (message.type) {
      case MessageType.roomUpdate:
        currentRoom = QuizRoom.fromJson(message.data);
        // print(
        //   '房间状态更新 - 状态: ${currentRoom!.status}, 题目: ${currentRoom!.currentQuestionIndex}, 玩家数: ${currentRoom!.players.length}',
        // );
        _roomUpdateController?.add(currentRoom!);
        break;

      case MessageType.startGame:
      case MessageType.showAnswer:
      case MessageType.nextQuestion:
        // 这些消息通过roomUpdate处理
        //print('收到专用消息类型: ${message.type}');
        break;

      default:
        //print('未知消息类型: ${message.type}');
        break;
    }
  }
  // catch (e) {
  //   print('处理服务器消息失败: $e');
  //   print('错误消息内容: $line');
  // }
  // }

  /// 玩家准备
  void playerReady(bool isReady) {
    if (_tcp == null || myPlayerId == null) {
      // print('无法发送准备状态：Socket或玩家ID为空');
      return;
    }

    try {
      final message = NetworkMessage(
        type: MessageType.playerReady,
        data: {'playerId': myPlayerId, 'isReady': isReady},
      );
      _networkService.sendMessage(_tcp!, message);
    } catch (e) {
      // print('发送准备状态失败: $e');
    }
  }

  /// 提交答案
  void submitAnswer(dynamic answerIndex) {
    if (_tcp == null || myPlayerId == null) {
      // print('无法提交答案：Socket或玩家ID为空');
      return;
    }

    try {
      final message = NetworkMessage(
        type: MessageType.playerAnswer,
        data: {'playerId': myPlayerId, 'answerIndex': answerIndex},
      );
      _networkService.sendMessage(_tcp!, message);
    } catch (e) {
      // print('提交答案失败: $e');
    }
  }

  void _updateStatus(String status) {
    if (_statusController != null && !_statusController!.isClosed) {
      _statusController!.add(status);
    }
  }

  /// 清理连接资源(内部方法)
  Future<void> _cleanupConnection() async {
    // print('清理客户端连接资源...');

    // 取消TCP订阅
    try {
      await _tcpSub?.cancel();
      _tcpSub = null;
    } catch (e) {
      // print('取消TCP订阅失败: $e');
    }

    // 关闭TCP连接
    try {
      _tcp?.destroy();
      _tcp = null;
      // 等待连接完全关闭
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      // print('关闭TCP连接失败: $e');
    }

    // 关闭UDP
    try {
      _udp?.close();
      _udp = null;
    } catch (e) {
      // print('关闭UDP失败: $e');
    }

    // 清理状态
    currentRoom = null;
    myPlayerId = null;
    _myIp = null;

    // print('客户端连接资源清理完成');
  }

  /// 断开连接
  Future<void> dispose() async {
    // print('客户端服务正在关闭...');

    // 清理连接资源
    await _cleanupConnection();

    // 关闭stream controller
    if (_roomUpdateController != null && !_roomUpdateController!.isClosed) {
      try {
        _roomUpdateController!.close();
      } catch (e) {
        // print('关闭房间更新控制器失败: $e');
      }
    }

    if (_statusController != null && !_statusController!.isClosed) {
      try {
        _statusController!.close();
      } catch (e) {
        // print('关闭状态控制器失败: $e');
      }
    }

    if (_disconnectController != null && !_disconnectController!.isClosed) {
      try {
        _disconnectController!.close();
      } catch (e) {
        // print('关闭断连控制器失败: $e');
      }
    }

    // print('客户端服务已完全关闭');
  }
}
