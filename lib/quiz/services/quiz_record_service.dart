import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';
import '../models/game_record_model.dart';

/// 游戏记录存储服务
class GameRecordService {
  static const String _recordsKey = 'game_records';
  static const int _maxRecords = 100; // 最多保存100条记录

  /// 保存游戏记录
  Future<void> saveRecord(GameRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getRecords();

    // 在列表开头插入新记录（最新的在前）
    records.insert(0, record);

    // 如果超过最大记录数，删除最旧的记录
    if (records.length > _maxRecords) {
      records.removeRange(_maxRecords, records.length);
    }

    // 序列化并保存
    final jsonList = records.map((r) => r.toJson()).toList();
    await prefs.setString(_recordsKey, jsonEncode(jsonList));
  }

  /// 获取所有游戏记录
  Future<List<GameRecord>> getRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_recordsKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => GameRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      appLogger.e('Failed to parse game records', e);
      // 解析失败，返回空列表
      return [];
    }
  }

  /// 删除指定记录
  Future<void> deleteRecord(String recordId) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getRecords();

    records.removeWhere((r) => r.id == recordId);

    final jsonList = records.map((r) => r.toJson()).toList();
    await prefs.setString(_recordsKey, jsonEncode(jsonList));
  }

  /// 清空所有记录
  Future<void> clearAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recordsKey);
  }

  /// 获取统计信息
  Future<GameStatistics> getStatistics() async {
    final records = await getRecords();

    if (records.isEmpty) {
      return GameStatistics(
        totalGames: 0,
        wins: 0,
        losses: 0,
        draws: 0,
        winRate: 0.0,
      );
    }

    int wins = 0;
    int losses = 0;
    int draws = 0;

    for (var record in records) {
      switch (record.result) {
        case GameResult.win:
          wins++;
          break;
        case GameResult.lose:
          losses++;
          break;
        case GameResult.draw:
          draws++;
          break;
      }
    }

    final winRate = records.isNotEmpty ? (wins / records.length) * 100 : 0.0;

    return GameStatistics(
      totalGames: records.length,
      wins: wins,
      losses: losses,
      draws: draws,
      winRate: winRate,
    );
  }
}

/// 游戏统计信息
class GameStatistics {
  final int totalGames; // 总对局数
  final int wins; // 胜利次数
  final int losses; // 失败次数
  final int draws; // 平局次数
  final double winRate; // 胜率（百分比）

  GameStatistics({
    required this.totalGames,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.winRate,
  });
}
