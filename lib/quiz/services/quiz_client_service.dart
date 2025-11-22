import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/quiz_room_model.dart';
import '../models/player_model.dart';
import 'quiz_network_service.dart';
import 'network_resource_manager.dart';

/// 客户端服务（玩家）
class QuizClientService with NetworkResourceManager {
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

  Timer? _heartbeatTimer;
  bool _isIntentionalDisconnect = false;
  (String, int)? _lastHost;
  QuizPlayer? _lastPlayer;

  /// 发现并连接到主机
  Future<bool> discoverAndConnect(QuizPlayer player) async {
    try {
      _isIntentionalDisconnect = false;
      _lastPlayer = player;

      // 先清理可能存在的旧连接
      await _cleanupConnection();

      // 重新创建StreamController(支持服务重用)
      _roomUpdateController = StreamController.broadcast();
      _statusController = StreamController.broadcast();
      _disconnectController = StreamController.broadcast();

      // 检查WiFi连接
      if (!await _networkService.isWiFiConnected()) {
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

      // 连接到主机
      if (!await _connectToHost(host, player)) {
        return false;
      }

      // 获取本地IP地址
      _myIp = await _networkService.getLocalIPv4();

      _updateStatus('已连接');
      return true;
    } catch (e) {
      _updateStatus(_networkService.getFriendlyErrorMessage(e));
      await _cleanupConnection();
      return false;
    }
  }

  /// 连接到主机
  Future<bool> _connectToHost(
    (String, int, String) host,
    QuizPlayer player,
  ) async {
    int retryCount = 0;
    const maxRetries = 3;

    _lastHost = (host.$1, host.$2);

    while (retryCount < maxRetries) {
      try {
        _tcp = await Socket.connect(
          host.$1,
          host.$2,
          timeout: const Duration(seconds: 5),
        );

        _tcp!.setOption(SocketOption.tcpNoDelay, true);
        break;
      } catch (e) {
        retryCount++;

        if (retryCount >= maxRetries) {
          _updateStatus(_networkService.getFriendlyErrorMessage(e));
          return false;
        }

        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }

    // 发送加入请求
    final joinMessage = NetworkMessage(
      type: MessageType.playerJoin,
      data: player.toJson(),
    );
    _networkService.sendMessage(_tcp!, joinMessage);

    // 启动心跳
    _startHeartbeat();

    // 监听消息
    _tcpSub = _networkService
        .socketLines(_tcp!)
        .listen(
          _handleServerMessage,
          onDone: _handleDisconnect,
          onError: (error) {
            // print('Socket error: $error');
            _handleDisconnect();
          },
          cancelOnError: false,
        );

    return true;
  }

  /// 启动心跳
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_tcp != null && myPlayerId != null) {
        try {
          _networkService.sendMessage(
            _tcp!,
            NetworkMessage(
              type: MessageType.heartbeat,
              data: {'playerId': myPlayerId},
            ),
          );
        } catch (e) {
          // 心跳发送失败通常意味着连接问题，会在socket error中处理
        }
      }
    });
  }

  /// 处理连接断开
  void _handleDisconnect() {
    if (_isIntentionalDisconnect) {
      _updateStatus('已断开连接');
      _disconnectController?.add(null);
      return;
    }

    _attemptReconnect();
  }

  /// 尝试重连
  Future<void> _attemptReconnect() async {
    if (_lastHost == null || _lastPlayer == null) return;

    _updateStatus('连接断开，正在尝试重连...');

    // 清理旧的socket资源，但保留状态
    await cancelSubscription(_tcpSub);
    _tcpSub = null;
    await closeSocket(_tcp);
    _tcp = null;
    _heartbeatTimer?.cancel();

    int retryCount = 0;
    const maxRetries = 10; // 增加重试次数

    while (retryCount < maxRetries && !_isIntentionalDisconnect) {
      try {
        await Future.delayed(const Duration(seconds: 2));
        retryCount++;
        _updateStatus('正在尝试重连 ($retryCount/$maxRetries)...');

        final socket = await Socket.connect(
          _lastHost!.$1,
          _lastHost!.$2,
          timeout: const Duration(seconds: 5),
        );

        _tcp = socket;
        _tcp!.setOption(SocketOption.tcpNoDelay, true);

        // 发送加入请求（重连）
        final joinMessage = NetworkMessage(
          type: MessageType.playerJoin,
          data: _lastPlayer!.toJson(),
        );
        _networkService.sendMessage(_tcp!, joinMessage);

        // 重新启动监听
        _tcpSub = _networkService
            .socketLines(_tcp!)
            .listen(
              _handleServerMessage,
              onDone: _handleDisconnect,
              onError: (e) => _handleDisconnect(),
              cancelOnError: false,
            );

        _startHeartbeat();
        _updateStatus('重连成功');

        // 可以在这里请求一次最新的房间状态，虽然Host在重连时会发送
        return;
      } catch (e) {
        // continue retry
      }
    }

    if (!_isIntentionalDisconnect) {
      _updateStatus('重连失败，请检查网络后手动重试');
      _disconnectController?.add(null);
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
      final message = NetworkMessage.fromJson(line);

      switch (message.type) {
        case MessageType.roomUpdate:
          currentRoom = QuizRoom.fromJson(message.data);
          _roomUpdateController?.add(currentRoom!);
          break;

        case MessageType.startGame:
        case MessageType.showAnswer:
        case MessageType.nextQuestion:
          // 这些消息通过roomUpdate处理
          break;

        default:
          break;
      }
    } catch (e) {
      // print('Error parsing message: $e');
    }
  }

  /// 玩家准备
  void playerReady(bool isReady) {
    if (_tcp == null || myPlayerId == null) {
      return;
    }

    try {
      final message = NetworkMessage(
        type: MessageType.playerReady,
        data: {'playerId': myPlayerId, 'isReady': isReady},
      );
      _networkService.sendMessage(_tcp!, message);
    } catch (e) {
      // 静默失败
    }
  }

  /// 提交答案
  void submitAnswer(dynamic answerIndex) {
    if (_tcp == null || myPlayerId == null) {
      return;
    }

    try {
      final message = NetworkMessage(
        type: MessageType.playerAnswer,
        data: {'playerId': myPlayerId, 'answerIndex': answerIndex},
      );
      _networkService.sendMessage(_tcp!, message);
    } catch (e) {
      // 静默失败
    }
  }

  void _updateStatus(String status) {
    if (_statusController != null && !_statusController!.isClosed) {
      _statusController!.add(status);
    }
  }

  /// 清理连接资源(内部方法)
  Future<void> _cleanupConnection() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    // 取消TCP订阅
    await cancelSubscription(_tcpSub);
    _tcpSub = null;

    // 关闭TCP连接
    await closeSocket(_tcp);
    _tcp = null;

    // 关闭UDP
    closeDatagramSocket(_udp);
    _udp = null;

    // 清理状态
    currentRoom = null;
    myPlayerId = null;
    _myIp = null;
  }

  /// 断开连接
  Future<void> dispose() async {
    _isIntentionalDisconnect = true;

    // 清理连接资源
    await _cleanupConnection();

    // 关闭stream controller
    await closeStreamController(_roomUpdateController);
    await closeStreamController(_statusController);
    await closeStreamController(_disconnectController);
  }
}
