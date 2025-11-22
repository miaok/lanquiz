import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/quiz_room_model.dart';
import '../models/player_model.dart';
import '../data/question_repository.dart';
import 'quiz_network_service.dart';
import 'quiz_game_controller.dart';
import 'network_resource_manager.dart';

/// 主机端服务（房主）
class QuizHostService with NetworkResourceManager {
  final QuizNetworkService _networkService = QuizNetworkService.instance;
  late QuizGameController gameController;

  ServerSocket? _server;
  RawDatagramSocket? _udp;
  Timer? _beacon;
  final List<Socket> _clients = [];
  final Map<Socket, String> _clientPlayerIds = {}; // Socket到玩家ID的映射

  StreamController<String>? _clientDisconnectController;
  Stream<String> get onClientDisconnected =>
      _clientDisconnectController!.stream;

  String? _hostIp;

  /// 获取主机IP地址
  String? get hostIp => _hostIp;

  /// 获取客户端列表（用于显示IP地址）
  List<Socket> get clients => _clients;

  /// 获取客户端玩家ID映射（用于匹配玩家和Socket）
  Map<Socket, String> get clientPlayerIds => _clientPlayerIds;

  /// 初始化主机
  Future<bool> initialize(QuizRoom room) async {
    try {
      // 先清理可能存在的旧连接
      await _cleanupResources();

      // 重新创建StreamController(支持服务重用)
      _clientDisconnectController = StreamController.broadcast();

      gameController = QuizGameController(room);

      // 检查WiFi连接
      if (!await _networkService.isWiFiConnected()) {
        return false;
      }

      // 获取本地WiFi IP
      _hostIp = await _networkService.getLocalIPv4();
      if (_hostIp == null) {
        return false;
      }

      // 绑定TCP服务器
      await _bindTcpServer();

      // 启动UDP广播
      await _startUdpBroadcast();

      // 监听房间更新
      gameController.roomUpdates.listen((room) {
        _broadcastRoomUpdate();
      });

      return true;
    } catch (e) {
      await _cleanupResources();
      return false;
    }
  }

  /// 绑定TCP服务器
  Future<void> _bindTcpServer() async {
    try {
      _server = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        QuizNetworkService.tcpPort,
        shared: true,
      );

      _server!.listen(_handleNewClient, cancelOnError: false);
    } catch (e) {
      // 尝试强制清理后重试一次
      await Future.delayed(const Duration(milliseconds: 500));
      await _cleanupResources();
      await Future.delayed(const Duration(milliseconds: 500));

      _server = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        QuizNetworkService.tcpPort,
        shared: true,
      );
      _server!.listen(_handleNewClient, cancelOnError: false);
    }
  }

  /// 启动UDP广播
  Future<void> _startUdpBroadcast() async {
    try {
      _udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _udp!.broadcastEnabled = true;
      _startBeacon();
    } catch (e) {
      // UDP失败不影响主要功能
    }
  }

  /// 清理资源(内部方法,不关闭gameController)
  Future<void> _cleanupResources() async {
    // 停止UDP广播
    cancelTimer(_beacon);
    _beacon = null;

    closeDatagramSocket(_udp);
    _udp = null;

    // 关闭所有客户端连接
    await closeSockets(_clients);
    _clientPlayerIds.clear();

    // 关闭服务器
    await closeServerSocket(_server);
    _server = null;
  }

  /// 启动UDP广播信标
  void _startBeacon() {
    _beacon = Timer.periodic(const Duration(seconds: 1), (timer) {
      final msg =
          '${QuizNetworkService.udpTag}:$_hostIp:${QuizNetworkService.tcpPort}:${gameController.room.name}';
      _udp?.send(
        utf8.encode(msg),
        InternetAddress('255.255.255.255'),
        QuizNetworkService.udpPort,
      );
    });
  }

  /// 处理新客户端连接
  void _handleNewClient(Socket client) {
    //print('新客户端连接: ${client.remoteAddress.address}');
    _clients.add(client);

    _networkService
        .socketLines(client)
        .listen(
          (line) => _handleClientMessage(client, line),
          onError: (error) => _removeClient(client),
          onDone: () => _removeClient(client),
          cancelOnError: true,
        );
  }

  /// 处理客户端消息
  void _handleClientMessage(Socket client, String line) {
    try {
      final message = NetworkMessage.fromJson(line);

      switch (message.type) {
        case MessageType.playerJoin:
          final player = QuizPlayer.fromJson(message.data);
          if (gameController.addPlayer(player)) {
            _clientPlayerIds[client] = player.id;
            //print('玩家 ${player.name} 加入房间');
          }
          break;

        case MessageType.playerReady:
          final playerId = message.data['playerId'];
          final isReady = message.data['isReady'];
          gameController.playerReady(playerId, isReady);
          break;

        case MessageType.playerAnswer:
          final playerId = message.data['playerId'];
          final answerIndex = message.data['answerIndex'];
          gameController.submitAnswer(playerId, answerIndex);
          break;

        default:
          break;
      }
    } catch (e) {
      //print('处理客户端消息失败: $e');
    }
  }

  /// 移除客户端
  void _removeClient(Socket client) {
    final playerId = _clientPlayerIds[client];
    if (playerId != null) {
      final player = gameController.room.players.firstWhere(
        (p) => p.id == playerId,
        orElse: () => QuizPlayer(id: '', name: 'Unknown'),
      );
      _clientDisconnectController?.add(player.name);
      gameController.removePlayer(playerId);
      _clientPlayerIds.remove(client);
    }
    _clients.remove(client);
    client.destroy();
  }

  /// 广播房间更新
  void _broadcastRoomUpdate() {
    // print(
    //   '广播房间更新 - 状态: ${gameController.room.status}, 题目: ${gameController.room.currentQuestionIndex}, 客户端数: ${_clients.length}',
    // );
    final message = NetworkMessage(
      type: MessageType.roomUpdate,
      data: gameController.room.toJson(),
    );
    _networkService.broadcastMessage(_clients, message);
    //print('房间更新已广播');
  }

  /// 开始游戏
  void startGame() {
    if (gameController.startGame()) {
      //print('开始游戏，广播房间状态');
      // gameController.startGame() 会触发 roomUpdates，自动广播更新
    }
  }

  // 题目配置
  int _trueFalseCount = 1;
  int _singleChoiceCount = 1;
  int _multipleChoiceCount = 1;

  /// 更新题目配置
  void updateQuestionConfig({
    required int trueFalseCount,
    required int singleChoiceCount,
    required int multipleChoiceCount,
  }) {
    _trueFalseCount = trueFalseCount;
    _singleChoiceCount = singleChoiceCount;
    _multipleChoiceCount = multipleChoiceCount;
  }

  /// 重新开始游戏（生成新题目）
  void restartGame() {
    final newQuestions = QuestionRepository.getQuestionsByConfig(
      trueFalseCount: _trueFalseCount,
      singleChoiceCount: _singleChoiceCount,
      multipleChoiceCount: _multipleChoiceCount,
    );
    gameController.restartGame(newQuestions);
    //print('游戏已重置，新题目已生成');
  }

  /// 关闭服务
  Future<void> dispose() async {
    // 关闭游戏控制器
    try {
      gameController.dispose();
    } catch (e) {
      // 静默失败
    }

    // 清理网络资源
    await _cleanupResources();

    // 关闭事件控制器
    await closeStreamController(_clientDisconnectController);
  }
}
