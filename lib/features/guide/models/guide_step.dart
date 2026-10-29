import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:flutter/material.dart';

/// 引导步骤标识。
///
/// 新增步骤时在此登记枚举值，并在 [guideStepSpecs] 中补充对应的展示描述。
enum GuideStep {
  /// 悬浮窗权限，Android 10 及以上系统后台读取剪贴板依赖该权限。
  floatPermission,

  /// 存储权限，同步图片与文件时需要。
  storagePermission,

  /// 工作模式选择，决定 Android 端以何种环境监听剪贴板。
  workingMode,

  /// 通知权限，前台服务依赖通知保持存活。
  notificationPermission,

  /// 电池优化白名单，降低被系统后台回收的概率。
  batteryOptimization,

  /// 引导结束页。
  finish,
}

/// 引导步骤定义。
///
/// 只描述「这一步讲什么、能不能跳过」，不持有 Widget 实例：文案以 [TranslationKey]
/// 形式保存，在 build 时才翻译，从而跟随语言切换刷新。
class GuideStepSpec {
  /// 步骤标识，同时作为完成状态的索引键。
  final GuideStep step;

  /// 步骤标题。
  final TranslationKey title;

  /// 步骤说明文案。
  final TranslationKey description;

  /// 步骤标题的插值参数，无参数时为空。
  final Map<String, String> descriptionParams;

  /// 步骤图标，为空时由具体内容组件自行决定。
  final IconData? icon;

  /// 是否允许在未完成时跳过。
  ///
  /// 不可跳过的步骤必须先完成授权才能前进。
  final bool skippable;

  const GuideStepSpec({
    required this.step,
    required this.title,
    required this.description,
    this.descriptionParams = const {},
    this.icon,
    this.skippable = false,
  });

  /// 翻译后的标题。
  String get titleText => title.tr;

  /// 翻译后的说明文案。
  String get descriptionText {
    if (descriptionParams.isEmpty) {
      return description.tr;
    } else {
      return description.trParams(descriptionParams);
    }
  }
}

/// 全部引导步骤的展示描述表。
///
/// 步骤是否出现在流程中由平台与系统版本在运行时决定，参见引导 bootstrap。
const Map<GuideStep, GuideStepSpec> guideStepSpecs = {
  GuideStep.floatPermission: GuideStepSpec(
    step: GuideStep.floatPermission,
    title: TranslationKey.floatPermGuideTitle,
    description: TranslationKey.floatPermGuideDesc,
    descriptionParams: {'appName': appName},
    icon: Icons.filter_none_rounded,
  ),
  GuideStep.storagePermission: GuideStepSpec(
    step: GuideStep.storagePermission,
    title: TranslationKey.storagePermGuideTitle,
    description: TranslationKey.storagePermGuideDesc,
    icon: Icons.storage_outlined,
    skippable: true,
  ),
  GuideStep.workingMode: GuideStepSpec(
    step: GuideStep.workingMode,
    title: TranslationKey.selectWorkMode,
    description: TranslationKey.selectWorkMode,
    icon: Icons.developer_mode,
  ),
  GuideStep.notificationPermission: GuideStepSpec(
    step: GuideStep.notificationPermission,
    title: TranslationKey.notificationPermGuideTitle,
    description: TranslationKey.notificationPermGuideDesc,
    icon: Icons.notifications_active_outlined,
  ),
  GuideStep.batteryOptimization: GuideStepSpec(
    step: GuideStep.batteryOptimization,
    title: TranslationKey.batteryOptimization,
    description: TranslationKey.batteryOptimizationPermGuideDesc,
    icon: Icons.battery_saver_outlined,
    skippable: true,
  ),
  GuideStep.finish: GuideStepSpec(
    step: GuideStep.finish,
    title: TranslationKey.completed,
    description: TranslationKey.completedGuideDesc,
    icon: Icons.check_circle,
  ),
};

/// 读取指定步骤的展示描述。
GuideStepSpec guideStepSpecOf(GuideStep step) => guideStepSpecs[step]!;