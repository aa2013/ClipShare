import 'dart:io';

import 'package:clipshare/core/runtime/app_update/app_update_provider.dart';
import 'package:clipshare/core/runtime/app_update/models/app_update_check_result.dart';
import 'package:clipshare/core/runtime/app_update/utils/app_update_installer.dart';
import 'package:clipshare/core/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/features/app_update/widgets/app_update_download_dialog.dart';
import 'package:clipshare/features/app_update/widgets/app_update_installer_selector.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 更新说明与操作界面；只通过 runtime 写入跳过版本。
class AppUpdateDialog extends ConsumerStatefulWidget {
  final AppUpdateCheckResult result;
  final BuildContext hostContext;
  final Future<void> Function() onClose;

  const AppUpdateDialog({super.key, required this.result, required this.hostContext, required this.onClose});

  @override
  ConsumerState<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends ConsumerState<AppUpdateDialog> {
  late final List<String> _types;
  late final ValueNotifier<String?> _selectedType;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _types = AppUpdateInstaller.installerTypes[defaultTargetPlatform] ?? const [];
    _selectedType = ValueNotifier(_types.firstOrNull);
  }

  @override
  void dispose() {
    _selectedType.dispose();
    super.dispose();
  }

  /// 将当前版本交由 runtime 忽略，异常保持可见而不丢失操作机会。
  Future<void> _ignoreVersion() async {
    setState(() => _busy = true);
    final notifier = ref.read(appUpdateProvider.notifier);
    try {
      await notifier.ignoreVersion(widget.result.logs.first.version.code);
      await widget.onClose();
    } catch (error, stack) {
      logger.error('AppUpdateDialog', '$error', stack);
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// 在关闭更新提示前捕获所有输入，下载窗口不再访问已释放的 notifier。
  Future<void> _download() async {
    setState(() => _busy = true);
    final host = widget.hostContext;
    final log = widget.result.logs.first;
    final type = _selectedType.value;
    var url = log.downloadUrl;
    try {
      final paths = ref.read(appPathsProvider).requireValue;
      final target = AppUpdateInstaller.resolve(log, paths.updateDownloadFileDirPath, installerType: type);
      url = target.url;
      await File(target.path).parent.create(recursive: true);
      if (!mounted || !host.mounted) {
        return;
      }
      await widget.onClose();
      if (!host.mounted || DialogManager.suppressTips?.call() == true) {
        return;
      }
      dialogManager.open(host, AppUpdateDownloadDialog(
        url: target.url,
        path: target.path,
        fileName: target.fileName,
        installerType: type,
        hostContext: host,
      ), dismissible: false);
    } catch (error, stack) {
      logger.error('AppUpdateDialog', '$error', stack);
      if (mounted) {
        setState(() => _busy = false);
      }
      if (host.mounted) {
        url.askOpenUrl(host);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.result.logs.map((log) => '🏷️${log.version}\n${log.desc}\n').join('\n');
    return AlertDialog(
      title: Text(TranslationKey.newVersionDialogTitle.tr),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(child: SingleChildScrollView(child: Text(content))),
            if (_types.isNotEmpty) AppUpdateInstallerSelector(types: _types, selectedType: _selectedType),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : _ignoreVersion, child: Text(TranslationKey.newVersionDialogSkipText.tr)),
        TextButton(onPressed: _busy ? null : widget.onClose, child: Text(TranslationKey.dialogCancelText.tr)),
        TextButton(onPressed: _busy ? null : _download, child: Text(TranslationKey.newVersionDialogOkText.tr)),
      ],
    );
  }
}
