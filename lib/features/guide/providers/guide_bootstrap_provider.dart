import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/settings/clipboard/clipboard_settings_provider.dart';
import 'package:clipshare/features/guide/models/guide_step.dart';
import 'package:clipshare/features/guide/providers/guide_step_handler_provider.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guide_bootstrap_provider.g.dart';

/// 需要引导的最低 Android 版本。
///
/// Android 10 以下系统可以直接读取剪贴板，既不需要悬浮窗权限也不需要选择工作模式。
const _minAndroidVersionForGuide = 10.0;

/// 引导流程的初始上下文。
class GuideBootstrap {
  /// 参与本次引导的步骤，按页面展示顺序排列。
  final List<GuideStepSpec> steps;

  /// 各步骤的初始完成状态。
  final Map<GuideStep, bool> completed;

  const GuideBootstrap({
    required this.steps,
    required this.completed,
  });

}

/// 组装引导流程的步骤清单与初始完成状态。
///
/// 启动流程完成后即可读取，用于判断是否需要展示引导页。
@riverpod
class GuideBootstrapNotifier extends _$GuideBootstrapNotifier {
  static const tag = 'GuideBootstrapNotifier';

  @override
  Future<GuideBootstrap> build() async {
    final double androidOsVersion;
    if (isAndroid) {
      final localDeviceInfo = await ref.watch(localDeviceInfoProvider.future);
      androidOsVersion = localDeviceInfo.androidOsVersion;
      // todo 挪动到初始化完成后
      // await _applyLegacyWorkingMode(androidOsVersion);
    } else {
      androidOsVersion = 0.0;
    }
    final steps = _buildSteps(androidOsVersion);
    return GuideBootstrap(steps: steps, completed: await _resolveCompleted(steps));
  }

  /// 组装步骤清单。
  ///
  /// 权限声明体系只覆盖 Android / iOS，桌面端无需引导；
  /// Android 10 以下系统跳过悬浮窗与工作模式选择两步。
  List<GuideStepSpec> _buildSteps(double androidOsVersion) {
    if (!isAndroid) {
      return const [];
    }
    final needsWorkMode = androidOsVersion >= _minAndroidVersionForGuide;
    return [
      if (needsWorkMode) guideStepSpecOf(GuideStep.floatPermission),
      guideStepSpecOf(GuideStep.storagePermission),
      if (needsWorkMode) guideStepSpecOf(GuideStep.workingMode),
      guideStepSpecOf(GuideStep.notificationPermission),
      guideStepSpecOf(GuideStep.batteryOptimization),
      guideStepSpecOf(GuideStep.finish),
    ];
  }

  /// 查询各步骤完成状态；没有权限诉求的步骤恒为已完成。
  Future<Map<GuideStep, bool>> _resolveCompleted(
    List<GuideStepSpec> steps,
  ) async {
    final results = await Future.wait(steps.map(_isCompleted));
    return {
      for (var i = 0; i < steps.length; i++)
        steps[i].step: results[i],
    };
  }

  /// 查询单个步骤是否已完成，查询异常按未完成处理并记录日志。
  Future<bool> _isCompleted(GuideStepSpec step) async {
    final handler = await ref.read(guideStepHandlerProvider(step.step).future);
    if (handler == null) {
      return true;
    }
    try {
      final result = await handler.hasPermission();
      return result;
    } catch (err, stack) {
      logger.error(tag, err, stack);
      return false;
    }
  }

  /// Android 10 以下系统固定使用 pre10 环境监听剪贴板。
  ///
  /// 引导页不展示工作模式选择，这里补齐该系统版本的默认工作模式，
  /// 避免配置停留在「未选择」状态。
  Future<void> _applyLegacyWorkingMode(double androidOsVersion) async {
    if (androidOsVersion >= _minAndroidVersionForGuide) {
      return;
    }
    final settings = await ref.read(clipboardSettingsProvider.future);
    if (settings.workingMode != EnvironmentType.none) {
      return;
    }
    final db = await ref.read(appDbProvider.future);
    await db.configDao.addOrUpdate(
      ConfigKey.workingMode,
      EnvironmentType.androidPre10.name,
    );
    ref.invalidate(clipboardSettingsProvider);
  }
}
