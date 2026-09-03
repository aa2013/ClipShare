import 'package:clipshare/core/utils/dialog.dart';
import 'package:flutter/material.dart';

/// 调试页：仅 debug 构建可见，用于手动验证各类组件与弹窗。
class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: () => _openFrame(context),
              icon: const Icon(Icons.crop_free),
              label: const Text('通用弹窗边框（默认尺寸）'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _openFrame(
                context,
                width: 600,
                height: 500,
                dismissible: false,
                showCloseButton: false,
              ),
              icon: const Icon(Icons.aspect_ratio),
              label: const Text('自定义尺寸 / 禁止空白关闭 / 隐藏关闭按钮'),
            ),
          ],
        ),
      ),
    );
  }

  /// 弹出通用边框弹窗；正文由示例 widget 填充，演示外部内容接入。
  void _openFrame(
    BuildContext context, {
    double? width,
    double? height,
    bool dismissible = true,
    bool showCloseButton = true,
  }) {
    dialogManager.frame(
      context,
      icon: Icons.bug_report_outlined,
      title: '调试弹窗',
      width: width,
      height: height,
      dismissible: dismissible,
      showCloseButton: showCloseButton,
      content: const _DebugFrameContent(),
    );
  }
}

/// 弹窗正文示例：由外部传入的 widget 填充整个内容区。
class _DebugFrameContent extends StatelessWidget {
  const _DebugFrameContent();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: 30,
      itemBuilder: (context, index) => ListTile(
        dense: true,
        title: Text('外部内容项 $index'),
      ),
    );
  }
}
