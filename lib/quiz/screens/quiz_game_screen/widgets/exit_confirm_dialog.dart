import 'package:flutter/material.dart';
import '../../../services/quiz_host_service.dart';
import '../../../services/quiz_client_service.dart';

/// 退出确认对话框
class ExitConfirmDialog extends StatelessWidget {
  final bool isHost;
  final QuizHostService? hostService;
  final QuizClientService? clientService;

  const ExitConfirmDialog({
    super.key,
    required this.isHost,
    this.hostService,
    this.clientService,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text('退出对局', style: textTheme.titleLarge),
      content: Text('确定要退出对局吗?', style: textTheme.bodyMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () async {
            // 在异步操作前保存 navigator 引用
            final navigator = Navigator.of(context);
            navigator.pop(); // 关闭对话框

            // 清理服务资源
            if (isHost) {
              await hostService?.dispose();
            } else {
              await clientService?.dispose();
            }

            // 返回主页 - 使用保存的 navigator 引用
            if (context.mounted) {
              navigator.popUntil((route) => route.isFirst);
            }
          },
          child: Text('退出', style: TextStyle(color: colorScheme.onSecondary)),
        ),
      ],
    );
  }

  /// 显示退出确认对话框
  static Future<void> show(
    BuildContext context, {
    required bool isHost,
    QuizHostService? hostService,
    QuizClientService? clientService,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ExitConfirmDialog(
        isHost: isHost,
        hostService: hostService,
        clientService: clientService,
      ),
    );
  }
}
