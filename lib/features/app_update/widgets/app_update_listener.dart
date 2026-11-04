import 'dart:async';

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/runtime/app_state/app_state.dart';
import 'package:clipshare/core/runtime/app_state/app_state_provider.dart';
import 'package:clipshare/core/runtime/app_update/app_update_provider.dart';
import 'package:clipshare/core/runtime/app_update/enums/app_update_check_status.dart';
import 'package:clipshare/core/runtime/app_update/models/app_update_check_result.dart';
import 'package:clipshare/core/settings/app_update/app_update_settings_provider.dart';
import 'package:clipshare/features/app_update/utils/app_update_dialog.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 根层更新事件消费者；先订阅，再在启动完成后开启自动检查。
class AppUpdateListener extends ConsumerStatefulWidget {
  final Widget child;

  const AppUpdateListener({super.key, required this.child});

  @override
  ConsumerState<AppUpdateListener> createState() => _AppUpdateListenerState();
}

class _AppUpdateListenerState extends ConsumerState<AppUpdateListener> {
  static const _tag = 'AppUpdateListener';
  StreamSubscription<AppUpdateCheckResult>? _subscription;
  AppUpdateCheckResult? _pending;
  bool _framePending = false;
  bool _presenting = false;

  /// 事件订阅覆盖整个应用生命周期，不依赖设置页面是否存在。
  @override
  void initState() {
    super.initState();
    final updater = ref.read(appUpdateProvider.notifier);
    _subscription = updater.events.listen(_onResult);
    ref.listenManual(appStateProvider, (previous, next) {
      if (next.initStatus == .initialized && previous?.initStatus != .initialized) {
        unawaited(_startAutomaticChecks());
      }
      if (!next.authenticating) {
        _schedulePresentation();
      }
    }, fireImmediately: true);
  }

  /// 调度注册失败只记录日志，不让启动过程出现未处理的异步异常。
  Future<void> _startAutomaticChecks() async {
    try {
      final updater = ref.read(appUpdateProvider.notifier);
      await updater.startAutomaticChecks();
    } catch (error, stack) {
      logger.error(_tag, '自动更新检查注册失败: $error', stack);
    }
  }

  /// 自动失败不打扰用户；可展示结果只保留最近一次。
  void _onResult(AppUpdateCheckResult result) {
    if (!mounted || result.status != AppUpdateCheckStatus.available) {
      return;
    }
    _pending = result;
    _schedulePresentation();
  }

  /// 推迟到帧结束，避免启动路由切换或解锁回调期间操作导航栈。
  void _schedulePresentation() {
    if (!mounted || _pending == null || _framePending) {
      return;
    }
    _framePending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _framePending = false;
      if (mounted) {
        unawaited(_presentPending());
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// 解锁后重新读取忽略设置，防止等待期间已跳过的版本再次弹出。
  Future<void> _presentPending() async {
    final result = _pending;
    if (_presenting || result == null || DialogManager.suppressTips?.call() == true) {
      return;
    }
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      _schedulePresentation();
      return;
    }
    _presenting = true;
    try {
      final settings = await ref.read(appUpdateSettingsProvider.future);
      if (!mounted || !context.mounted || !identical(_pending, result)) {
        return;
      }
      if (DialogManager.suppressTips?.call() == true) {
        return;
      }
      if (!result.forceCheck && settings.ignoreUpdateVersion == result.logs.first.version.code) {
        _pending = null;
        return;
      }
      final displayed = await showAppUpdateDialog(context, result);
      if (mounted && displayed && identical(_pending, result)) {
        _pending = null;
      }
    } catch (error, stack) {
      logger.error(_tag, '更新提示展示失败: $error', stack);
    } finally {
      _presenting = false;
      // 展示过程中到来的新结果继续处理；同一失败结果不逐帧重试。
      if (mounted && _pending != null && !identical(_pending, result)) {
        _schedulePresentation();
      }
    }
  }

  /// 销毁时只清理更新提示，不影响其他业务弹窗。
  @override
  void dispose() {
    _subscription?.cancel();
    _pending = null;
    unawaited(closeAppUpdateDialog());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
