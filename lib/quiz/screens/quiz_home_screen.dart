import 'package:flutter/material.dart';
import 'dart:math';
import 'quiz_host_screen.dart';
import 'quiz_client_screen.dart';

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
    for (int i = 0; i < 3; i++) {
      nickname += letters[_random.nextInt(letters.length)];
    }
    
    // 生成2个随机数字
    for (int i = 0; i < 2; i++) {
      nickname += numbers[_random.nextInt(numbers.length)];
    }
    
    return nickname;
  }

  /// 点击随机图标时生成新昵称
  void _generateNewNickname() {
    setState(() {
      _nameController.text = _generateRandomNickname();
    });
    
    // 显示提示消息
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('新昵称：${_nameController.text}'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 标题
                Icon(Icons.quiz, size: 80, color: Colors.blue[700]),
                const SizedBox(height: 16),
                Text(
                  '知识竞答',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 32),

                // 输入框
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: '请输入您的昵称',
                      prefixIcon: const Icon(Icons.person),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.shuffle),
                        onPressed: _generateNewNickname,
                        tooltip: '生成随机昵称',
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
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
                        child: ElevatedButton.icon(
                          onPressed: _createRoom,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text(
                            '创建房间',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                          label: const Text(
                            '加入房间',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue[700],
                            side: BorderSide(
                              color: Colors.blue[700]!,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _createRoom() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入昵称')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QuizHostScreen(playerName: name)),
    );
  }

  void _joinRoom() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入昵称')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizClientScreen(playerName: name),
      ),
    );
  }
}