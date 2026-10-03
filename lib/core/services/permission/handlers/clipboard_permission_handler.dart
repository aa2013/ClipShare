import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:flutter/cupertino.dart';

import 'abstract_permission_handler.dart';

/// 剪贴板权限处理请求。
///
/// Android 10 及以上系统读取剪贴板受后台限制，具体能力由工作模式（Shizuku/root）决定。
class ClipboardPermissionHandler extends AbstractPermissionHandler {
  @override
  Future<void> request(BuildContext context) async {
    await clipboardManager.requestClipboardPermission();
  }

  @override
  Future<bool> hasPermission() {
    return clipboardManager.checkClipboardPermission();
  }
}
