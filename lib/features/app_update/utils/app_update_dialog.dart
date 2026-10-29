import 'dart:async';

import 'package:clipshare/core/runtime/app_update/enums/app_update_check_status.dart';
import 'package:clipshare/core/runtime/app_update/models/app_update_check_result.dart';
import 'package:clipshare/core/services/notify/notify_provider.dart';
import 'package:clipshare/features/app_update/widgets/app_update_dialog.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synchronized/synchronized.dart';

final _updateDialogLock = Lock();
DialogController? _updateDialog;
int _requestId = 0;
const _notificationKey = 'appUpdate';
const _notificationLifetime = Duration(seconds: 2);

/// 展示最新更新结果；返回是否实际打开，只等待替换与打开，不等待用户关闭窗口。
/// [sendNotification] 控制是否同时发出两秒系统通知，默认保留更新通知行为。
/// 被应用锁抑制时不消费结果，由根监听暂存并在解锁后重试。
Future<bool> showAppUpdateDialog(BuildContext context, AppUpdateCheckResult result, {
  bool sendNotification = true,
}) async {
  if (!context.mounted || DialogManager.suppressTips?.call() == true ||
      result.status != .available || result.logs.isEmpty) {
    return false;
  }
  final request = ++_requestId;
  return _updateDialogLock.synchronized(() async {
    if (request != _requestId || !context.mounted || DialogManager.suppressTips?.call() == true) {
      return false;
    }
    await _closeCurrentDialog();
    if (request != _requestId || !context.mounted || DialogManager.suppressTips?.call() == true) {
      return false;
    }
    late final DialogController controller;
    controller = dialogManager.open(context, AppUpdateDialog(
      result: result,
      hostContext: context,
      onClose: () => _closeOwnedDialog(controller),
    ));
    _updateDialog = controller;
    unawaited(controller.future.then((_) {
      if (identical(_updateDialog, controller)) {
        _updateDialog = null;
      }
    }));
    if (sendNotification) {
      try {
        final container = ProviderScope.containerOf(context, listen: false);
        final notifier = container.read(notifyProvider.notifier);
        unawaited(_notifyUpdate(notifier, result));
      } catch (error, stack) {
        logger.error('AppUpdateDialog', '读取通知服务失败: $error', stack);
      }
    }
    return true;
  });
}

/// 仅关闭由更新入口持有的窗口，同时使尚未执行的展示请求失效。
Future<void> closeAppUpdateDialog() async {
  ++_requestId;
  await _updateDialogLock.synchronized(_closeCurrentDialog);
}

/// 操作按钮绑定准确的 controller，旧窗口回调不会误关新窗口。
Future<void> _closeOwnedDialog(DialogController controller) async {
  await _updateDialogLock.synchronized(() async {
    if (identical(_updateDialog, controller)) {
      await _closeCurrentDialog();
    }
  });
}

/// 等待退场完成后才允许下一个更新窗口进场，不操作其它业务 route。
Future<void> _closeCurrentDialog() async {
  final controller = _updateDialog;
  if (controller == null) {
    return;
  }
  if (controller.key.currentContext == null && !controller.closed) {
    await WidgetsBinding.instance.endOfFrame;
  }
  final dialogContext = controller.key.currentContext;
  final route = dialogContext == null || !dialogContext.mounted ? null : ModalRoute.of(dialogContext);
  await controller.close();
  if (route != null) {
    await route.completed;
  }
  if (identical(_updateDialog, controller)) {
    _updateDialog = null;
  }
}

/// 通知失败不影响已打开的界面，取消使用精确 id 避免撤回后续通知。
Future<void> _notifyUpdate(NotifyNotifier notifier, AppUpdateCheckResult result) async {
  try {
    final id = await notifier.notify(
      content: '${TranslationKey.newVersionAvailable.tr} ${result.logs.first.version}',
      key: _notificationKey,
    );
    if (id != null) {
      await Future<void>.delayed(_notificationLifetime);
      notifier.cancel(_notificationKey, id);
    }
  } catch (error, stack) {
    logger.error('AppUpdateDialog', '通知更新失败: $error', stack);
  }
}
