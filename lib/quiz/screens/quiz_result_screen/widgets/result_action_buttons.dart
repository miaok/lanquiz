import 'package:flutter/material.dart';
import '../../../services/quiz_host_service.dart';
import '../../../services/quiz_client_service.dart';
import '../../quiz_home_screen.dart';

/// 结果页面操作按钮组件
class ResultActionButtons extends StatelessWidget {
  final bool isHost;
  final QuizHostService? hostService;
  final QuizClientService? clientService;

  const ResultActionButtons({
    super.key,
    required this.isHost,
    this.hostService,
    this.clientService,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 再来一局按钮（仅房主可见）
          if (isHost) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () => hostService?.restartGame(),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('再来一局', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 返回主页按钮
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.tonal(
              onPressed: () => _handleReturnHome(context),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('返回主页', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  /// 处理返回主页
  Future<void> _handleReturnHome(BuildContext context) async {
    // 如果是房主且点击返回主页,应该关闭服务
    if (isHost) {
      await hostService?.dispose();
    } else {
      await clientService?.dispose();
    }

    // 确保widget仍然挂载且context有效
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const QuizHomeScreen()),
      (route) => false,
    );
  }
}
