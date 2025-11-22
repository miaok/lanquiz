/// 游戏记录模型
class GameRecord {
  final String id; // 对局唯一ID
  final DateTime timestamp; // 对局时间
  final String hostId; // 主机玩家ID
  final String hostName; // 主机玩家昵称
  final String clientId; // 客户端玩家ID
  final String clientName; // 客户端玩家昵称
  final int totalQuestions; // 总题数
  final int hostScore; // 主机得分
  final int clientScore; // 客户端得分
  final int durationSeconds; // 对局用时（秒）
  final GameResult result; // 对局结果（从主机视角）

  GameRecord({
    required this.id,
    required this.timestamp,
    required this.hostId,
    required this.hostName,
    required this.clientId,
    required this.clientName,
    required this.totalQuestions,
    required this.hostScore,
    required this.clientScore,
    required this.durationSeconds,
    required this.result,
  });

  /// 从JSON反序列化
  factory GameRecord.fromJson(Map<String, dynamic> json) {
    return GameRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      hostId: json['hostId'] as String,
      hostName: json['hostName'] as String,
      clientId: json['clientId'] as String,
      clientName: json['clientName'] as String,
      totalQuestions: json['totalQuestions'] as int,
      hostScore: json['hostScore'] as int,
      clientScore: json['clientScore'] as int,
      durationSeconds: json['durationSeconds'] as int,
      result: GameResult.values[json['result'] as int],
    );
  }

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'hostId': hostId,
      'hostName': hostName,
      'clientId': clientId,
      'clientName': clientName,
      'totalQuestions': totalQuestions,
      'hostScore': hostScore,
      'clientScore': clientScore,
      'durationSeconds': durationSeconds,
      'result': result.index,
    };
  }

  /// 获取胜者名称
  String get winnerName {
    switch (result) {
      case GameResult.win:
        return hostName;
      case GameResult.lose:
        return clientName;
      case GameResult.draw:
        return '平局';
    }
  }

  /// 获取分数差
  int get scoreDifference {
    return (hostScore - clientScore).abs();
  }
}

/// 游戏结果枚举（从主机视角）
enum GameResult {
  win, // 主机胜利
  lose, // 主机失败
  draw, // 平局
}
