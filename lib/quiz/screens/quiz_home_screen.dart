import 'package:flutter/material.dart';
import 'dart:math';
import 'quiz_host_screen.dart';
import 'quiz_client_screen.dart';
import 'quiz_records_screen.dart';
import '../widgets/theme_switcher.dart';
import '../services/quiz_network_service.dart';

/// 知识竞答主页
class QuizHomeScreen extends StatefulWidget {
  const QuizHomeScreen({super.key});

  @override
  State<QuizHomeScreen> createState() => _QuizHomeScreenState();
}

class _QuizHomeScreenState extends State<QuizHomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // 初始化时生成一个随机昵称
    _nameController.text = _generateRandomNickname();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// 生成随机昵称：3字母+2数字
  String _generateRandomNickname() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';

    String nickname = '';

    // 生成3个随机字母
    for (int i = 0; i < 2; i++) {
      nickname += letters[_random.nextInt(letters.length)];
    }

    // 生成2个随机数字
    for (int i = 0; i < 3; i++) {
      nickname += numbers[_random.nextInt(numbers.length)];
    }

    return nickname;
  }

  /// 点击随机图标时生成新昵称
  void _generateNewNickname() {
    setState(() {
      _nameController.text = _generateRandomNickname();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 获取主题色彩方案
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _viewGameRecords,
        icon: const Icon(Icons.history),
        label: const Text('对战记录'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // 主题切换按钮（右上角）
            Positioned(top: 8, right: 8, child: const ThemeSwitcher()),
            // 主要内容
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 标题
                    Icon(
                      Icons.flutter_dash,
                      size: 100,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '1V1挑战',
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 输入框
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '请输入您的昵称',
                          prefixIcon: Icon(Icons.person),
                          suffixIcon: _ShuffleIconButton(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 按钮
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton.icon(
                              onPressed: _createRoom,
                              icon: const Icon(Icons.add_circle_outline),
                              label: Text(
                                '创建房间',
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: _joinRoom,
                              icon: const Icon(Icons.login),
                              label: Text('加入房间', style: textTheme.titleMedium),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createRoom() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入昵称')));
      return;
    }

    // 检查WiFi连接
    final networkService = QuizNetworkService.instance;
    final isWiFi = await networkService.isWiFiConnected();
    if (!isWiFi) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('未连接WiFi，请连接WiFi局域网后重试'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QuizHostScreen(playerName: name)),
    );
  }

  void _joinRoom() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入昵称')));
      return;
    }

    // 检查WiFi连接
    final networkService = QuizNetworkService.instance;
    final isWiFi = await networkService.isWiFiConnected();
    if (!isWiFi) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('未连接WiFi，请连接WiFi局域网后重试'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizClientScreen(playerName: name),
      ),
    );
  }

  void _viewGameRecords() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GameRecordsScreen()),
    );
  }
}

/// Shuffle 图标按钮组件
class _ShuffleIconButton extends StatelessWidget {
  const _ShuffleIconButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.shuffle),
      onPressed: () {
        final state = context.findAncestorStateOfType<_QuizHomeScreenState>();
        state?._generateNewNickname();
      },
      tooltip: '生成随机昵称',
    );
  }
}
