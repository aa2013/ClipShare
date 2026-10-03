import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/services/clipboard/clipboard_service_provider.dart';
import 'package:clipshare/core/settings/clipboard/clipboard_settings_provider.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'android_environment_status_provider.g.dart';

/// Android 剪贴板工作环境的健康状态。
///
/// 只描述「检查完成后的结论」；首轮检查未完成时 provider 处于加载态，
/// 不在此枚举中表达加载态，避免加载态被误当作一种环境结论参与后续判断。
enum AndroidEnvironmentHealth {
  /// 特权环境已授权且剪贴板监听服务已就绪
  normal,

  /// 特权环境缺少授权，或监听服务尚未就绪
  warning,

  /// 未选择工作环境（[EnvironmentType.none]），按无需特权环境处理
  ignored,
}

/// Android 剪贴板工作环境状态快照。
@immutable
class AndroidEnvironmentStatus {
  /// 当前工作模式
  final EnvironmentType workingMode;

  /// 环境健康状态
  final AndroidEnvironmentHealth health;

  /// Shizuku API 版本，仅 Shizuku 模式且已授权时存在
  final int? shizukuVersion;

  const AndroidEnvironmentStatus({
    required this.workingMode,
    required this.health,
    this.shizukuVersion,
  });
}

/// Android 剪贴板工作环境状态。
///
/// 状态由「工作模式配置 + 特权环境授权 + 监听服务是否就绪」三者共同决定，
/// 三个来源都会在运行期变化：工作模式配置变化时本 provider 自动重建，
/// 从系统授权页返回、Shizuku 断开等场景由 [refresh] 复查。
@Riverpod(keepAlive: true)
class AndroidEnvironmentStatusNotifier extends _$AndroidEnvironmentStatusNotifier {
  /// 检查序号：并发检查时只采纳最后一次结论，避免过期结果覆盖新状态。
  int _checkSeq = 0;

  /// 监听服务未就绪时的重试间隔。
  ///
  /// Shizuku/root 的前台通知可能早于实际监听服务 ready 出现，
  /// 这里用有界重试区间兜住启动期的瞬时未就绪，避免冷启动直接判为异常。
  static const List<Duration> listenerRunningRetryDelays = [
    Duration(milliseconds: 500),
    Duration(seconds: 1),
    Duration(milliseconds: 1500),
  ];

  @override
  Future<AndroidEnvironmentStatus> build() async {
    final workingMode = await ref.watch(
      clipboardSettingsProvider.selectAsync((settings) => settings.workingMode),
    );
    if (!isAndroid) {
      return AndroidEnvironmentStatus(
        workingMode: workingMode,
        health: AndroidEnvironmentHealth.ignored,
      );
    }
    // 标记新一轮检查：进行中的 refresh 结论随之作废，避免旧模式的状态覆盖新模式
    _checkSeq++;
    return _check(workingMode);
  }

  /// 重新检查工作环境状态，用于回到前台后刷新。
  ///
  /// 保留上一次检查结果直到新结论产出，避免从系统授权页返回时画面闪烁加载态。
  Future<void> refresh() async {
    if (!isAndroid) {
      return;
    }
    final seq = ++_checkSeq;
    final settings = await ref.read(clipboardSettingsProvider.future);
    final status = await _check(settings.workingMode);
    if (seq != _checkSeq) {
      // 期间已发起更新的检查，本次结论作废
      return;
    }
    state = AsyncData(status);
  }

  /// 重新申请工作环境授权并重启剪贴板监听。
  ///
  /// 仅在环境处于 [AndroidEnvironmentHealth.warning] 时有意义：
  /// 缺失授权时重新拉起授权流程并用最新配置重启监听，其余状态点击不做处理。
  Future<void> recover() async {
    if (!isAndroid) {
      return;
    }
    final current = state.value;
    if (current == null || current.health != AndroidEnvironmentHealth.warning) {
      return;
    }
    await clipboardManager.requestPermission(current.workingMode);
    final clipboardService = await ref.read(clipboardServiceProvider.future);
    await clipboardService.restartAndroidListening();
    await refresh();
  }

  /// 按当前工作模式检查授权与监听服务就绪状态。
  Future<AndroidEnvironmentStatus> _check(EnvironmentType workingMode) async {
    switch (workingMode) {
      case EnvironmentType.shizuku:
      case EnvironmentType.root:
        final granted = await clipboardManager.checkPermission(workingMode);
        if (!granted) {
          return AndroidEnvironmentStatus(
            workingMode: workingMode,
            health: AndroidEnvironmentHealth.warning,
          );
        }
        final listening = await _checkListenerRunning();
        return AndroidEnvironmentStatus(
          workingMode: workingMode,
          health: listening ? AndroidEnvironmentHealth.normal : AndroidEnvironmentHealth.warning,
          shizukuVersion: workingMode == EnvironmentType.shizuku ? await clipboardManager.getShizukuVersion() : null,
        );
      case EnvironmentType.androidPre10:
        // Android 10 以下系统不限制后台读取剪贴板，无需特权环境即可监听
        return const AndroidEnvironmentStatus(
          workingMode: EnvironmentType.androidPre10,
          health: AndroidEnvironmentHealth.normal,
        );
      case EnvironmentType.none:
        return const AndroidEnvironmentStatus(
          workingMode: EnvironmentType.none,
          health: AndroidEnvironmentHealth.ignored,
        );
    }
  }

  /// 确认剪贴板监听服务是否已就绪，仍未就绪时按 [listenerRunningRetryDelays] 有界重试。
  Future<bool> _checkListenerRunning() async {
    if (await clipboardManager.checkIsRunning()) {
      return true;
    }
    for (final delay in listenerRunningRetryDelays) {
      await Future.delayed(delay);
      if (await clipboardManager.checkIsRunning()) {
        return true;
      }
    }
    return false;
  }
}
