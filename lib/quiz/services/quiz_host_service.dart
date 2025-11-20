import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/quiz_room.dart';
import '../models/player.dart';
import '../data/question_repository.dart';
import 'quiz_network_service.dart';
import 'quiz_game_controller.dart';

/// 主机端服务（房主）
class QuizHostService {
  final QuizNetworkService _networkService = QuizNetworkService.instance;
  late QuizGameController gameController;

  ServerSocket? _server;
  RawDatagramSocket? _udp;
  Timer? _beacon;
  final List<Socket> _clients = [];
  final Map<Socket, String> _clientPlayerIds = {}; // Socket到玩家ID的映射

  final StreamController<String> _clientDisconnectController =
      StreamController.broadcast();
  Stream<String> get onClientDisconnected => _clientDisconnectController.stream;

  String? _hostIp;

  /// 初始化主机
  Future<bool> initialize(QuizRoom room) async {
    try {
      // 先清理可能存在的旧连接
      await _cleanupResources();

      gameController = QuizGameController(room);

      // 获取本地IP
      _hostIp = await _networkService.getLocalIPv4();
      print('尝试在 $_hostIp:${QuizNetworkService.tcpPort} 启动主机...');

      // 绑定TCP服务器,启用端口重用
      try {
        _server = await ServerSocket.bind(
          InternetAddress.anyIPv4,
          QuizNetworkService.tcpPort,
          shared: true, // 允许端口重用
        );

        // 设置服务器选项
        _server!.listen(
          _handleNewClient,
          onError: (error) {
            print('服务器监听错误: $error');
          },
          cancelOnError: false,
        );

        print('TCP服务器已启动,端口: ${QuizNetworkService.tcpPort}');
      } catch (e) {
        print('绑定TCP端口失败: $e');
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
        print('TCP服务器重试成功');
      }

      // 启动UDP广播
      try {
        _udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        _udp!.broadcastEnabled = true;
        _startBeacon();
        print('UDP广播已启动');
      } catch (e) {
        print('启动UDP广播失败: $e');
        // UDP失败不影响主要功能,继续运行
      }

      // 监听房间更新
      gameController.roomUpdates.listen((room) {
        _broadcastRoomUpdate();
      });

      print('主机已成功启动,IP: $_hostIp');
      return true;
    } catch (e, stackTrace) {
      print('初始化主机失败: $e');
      print('堆栈跟踪: $stackTrace');
      // 确保清理资源
      await _cleanupResources();
      return false;
    }
  }

  /// 清理资源(内部方法,不关闭gameController)
  Future<void> _cleanupResources() async {
    print('清理网络资源...');

    // 停止UDP广播
    _beacon?.cancel();
    _beacon = null;

    try {
      _udp?.close();
      _udp = null;
    } catch (e) {
      print('关闭UDP失败: $e');
    }

    // 关闭所有客户端连接
    for (final client in _clients.toList()) {
      try {
        client.destroy();
      } catch (e) {
        print('关闭客户端连接失败: $e');
      }
    }
    _clients.clear();
    _clientPlayerIds.clear();

    // 关闭服务器
    try {
      await _server?.close();
      _server = null;
      // 等待端口释放
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      print('关闭服务器失败: $e');
    }

    print('网络资源清理完成');
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
    print('新客户端连接: ${client.remoteAddress.address}');
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
            print('玩家 ${player.name} 加入房间');
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
      print('处理客户端消息失败: $e');
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
      _clientDisconnectController.add(player.name);
      gameController.removePlayer(playerId);
      _clientPlayerIds.remove(client);
    }
    _clients.remove(client);
    client.destroy();
  }

  /// 广播房间更新
  void _broadcastRoomUpdate() {
    print(
      '广播房间更新 - 状态: ${gameController.room.status}, 题目: ${gameController.room.currentQuestionIndex}, 客户端数: ${_clients.length}',
    );
    final message = NetworkMessage(
      type: MessageType.roomUpdate,
      data: gameController.room.toJson(),
    );
    _networkService.broadcastMessage(_clients, message);
    print('房间更新已广播');
  }

  /// 开始游戏
  void startGame() {
    if (gameController.startGame()) {
      print('开始游戏，广播房间状态');
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
    print('游戏已重置，新题目已生成');
  }

  /// 关闭服务
  Future<void> dispose() async {
    print('主机服务正在关闭...');

    // 关闭游戏控制器(停止发送更新)
    try {
      gameController.dispose();
    } catch (e) {
      print('关闭游戏控制器失败: $e');
    }

    // 清理网络资源
    await _cleanupResources();

    // 关闭事件控制器
    if (!_clientDisconnectController.isClosed) {
      try {
        _clientDisconnectController.close();
      } catch (e) {
        print('关闭断连控制器失败: $e');
      }
    }

    print('主机服务已完全关闭');
  }
}
