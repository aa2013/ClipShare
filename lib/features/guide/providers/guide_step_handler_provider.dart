import 'package:clipshare/core/platform/channels/android/android_channel_provider.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/permission/handlers/abstract_permission_handler.dart';
import 'package:clipshare/core/services/permission/handlers/android_storage_permission_handler.dart';
import 'package:clipshare/core/services/permission/handlers/float_permission_handler.dart';
import 'package:clipshare/core/services/permission/handlers/ignore_battery_permission_handler.dart';
import 'package:clipshare/core/services/permission/handlers/notify_permission_handler.dart';
import 'package:clipshare/core/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/features/guide/models/guide_step.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guide_step_handler_provider.g.dart';

/// 按步骤标识提供对应的权限处理器。
///
/// 引导流程的状态查询与步骤内容共用同一份处理器来源，避免两侧各自构造导致
/// 判定对象与实际授权对象不一致。纯信息步骤（工作模式、完成页）没有权限诉求，
/// 返回 null 表示其完成状态不由权限决定。
@riverpod
Future<AbstractPermissionHandler?> guideStepHandler(Ref ref, GuideStep id) async {
  return switch (id) {
    GuideStep.floatPermission => FloatPermissionHandler(
      ref.read(androidChannelProvider.notifier),
    ),
    GuideStep.notificationPermission => NotifyPermissionHandler(
      ref.read(androidChannelProvider.notifier),
    ),
    GuideStep.batteryOptimization => IgnoreBatteryPermissionHandler(),
    GuideStep.storagePermission => AndroidStoragePermissionHandler(
      (await ref.watch(appPathsProvider.future)).rootStorePath,
      (await ref.watch(localDeviceInfoProvider.future)).androidOsVersion,
    ),
    GuideStep.workingMode || GuideStep.finish => null,
  };
}