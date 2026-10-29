import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/runtime/app_update/utils/app_update_installer.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/snackbar.dart';
import 'package:clipshare/shared/widgets/loading/downloading_dialog.dart';
import 'package:flutter/material.dart';

/// 下载确认界面独立持有选择状态，关闭后释放 notifier。
class AppUpdateDownloadDialog extends StatefulWidget {
  final String url;
  final String path;
  final String fileName;
  final String? installerType;
  final BuildContext hostContext;

  const AppUpdateDownloadDialog({super.key, required this.url, required this.path,
    required this.fileName, required this.hostContext, this.installerType});

  @override
  State<AppUpdateDownloadDialog> createState() => _AppUpdateDownloadDialogState();
}

class _AppUpdateDownloadDialogState extends State<AppUpdateDownloadDialog> {
  final _openFolder = ValueNotifier<bool>(isLinux || isMacOS);
  bool _cancelled = false;

  @override
  void dispose() {
    _openFolder.dispose();
    super.dispose();
  }

  /// 下载成功后按用户选择安装；取消回调不能触发安装。
  Future<void> _onFinished(bool success) async {
    if (!success || _cancelled || !mounted) {
      return;
    }
    final openFolder = _openFolder.value;
    final host = widget.hostContext;
    try {
      final opened = await AppUpdateInstaller.install(widget.path,
        openFolder: openFolder, installerType: widget.installerType);
      if (!opened && host.mounted) {
        snackbar.warn(host, TranslationKey.openFailed.tr);
      }
    } catch (error, stack) {
      await _showError(error, stack);
    }
  }

  /// 使用宿主上下文显示异步错误，不依赖已退场的下载窗口。
  Future<void> _showError(Object error, StackTrace stack) async {
    logger.error('AppUpdateDownloadDialog', '$error', stack);
    final host = widget.hostContext;
    if (host.mounted) {
      await dialogManager.tips(host, text: 'error $error,$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DownloadDialog(
      url: widget.url,
      savePath: widget.path,
      onCancel: () => _cancelled = true,
      onFinished: _onFinished,
      onError: (error, stack) => _showError(error, stack),
      content: ValueListenableBuilder<bool>(
        valueListenable: _openFolder,
        builder: (context, value, child) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.fileName),
            const SizedBox(height: 5),
            CheckboxListTile(
              value: value,
              title: Text(TranslationKey.openPathAfterDownload.tr),
              onChanged: (value) => _openFolder.value = value ?? false,
            ),
          ],
        ),
      ),
    );
  }
}
