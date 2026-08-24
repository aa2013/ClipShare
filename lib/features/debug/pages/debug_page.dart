import 'package:clipshare/core/utils/dialog.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
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
              onPressed: () => _openFrame(
                context,
                footer: const Text('底部说明文字，可与按钮共存'),
                actions: _buildActions(),
              ),
              icon: const Icon(Icons.crop_free),
              label: const Text('通用弹窗边框（默认尺寸 + footer/actions）'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _openFrame(
                context,
                width: 600,
                height: 500,
                dismissible: false,
                showCloseButton: false,
                actions: _buildActions(),
              ),
              icon: const Icon(Icons.aspect_ratio),
              label: const Text('自定义尺寸 / 禁止空白关闭 / 隐藏关闭按钮'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建弹窗底部按钮组示例。
  DialogActions _buildActions() {
    return const DialogActions(
      cancel: DialogAction(text: '取消'),
      confirm: DialogAction(text: '确定'),
    );
  }

  /// 弹出通用边框弹窗；正文由示例 widget 填充，演示外部内容接入。
  void _openFrame(
    BuildContext context, {
    double? width,
    double? height,
    bool dismissible = true,
    bool showCloseButton = true,
    Widget? footer,
    DialogActions? actions,
  }) {
    dialogManager.frame(
      context,
      icon: Icons.bug_report_outlined,
      title: '调试弹窗',
      width: width,
      height: height,
      dismissible: dismissible,
      showCloseButton: showCloseButton,
      footer: footer,
      actions: actions,
      content: const _DebugFrameContent(),
    );
  }
}

/// 弹窗正文示例：非滚动内容，由边框统一包裹滚动以演示 header/footer 固定。
class _DebugFrameContent extends StatelessWidget {
  const _DebugFrameContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 30; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('外部内容项 $i'),
          ),
      ],
    );
  }
}
