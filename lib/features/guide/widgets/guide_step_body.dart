import 'package:clipshare/features/guide/models/guide_step.dart';
import 'package:clipshare/features/guide/widgets/finish_guide_body.dart';
import 'package:clipshare/features/guide/widgets/permission_guide_body.dart';
import 'package:clipshare/features/guide/widgets/working_mode_guide_body.dart';
import 'package:flutter/material.dart';

/// 按步骤标识分发具体内容组件。
///
/// 新增步骤时在此登记内容组件；未登记的步骤默认按权限类步骤渲染。
/// 文案随语言切换刷新由引导页统一订阅翻译对象后重建完成。
class GuideStepBody extends StatelessWidget {
  /// 步骤描述。
  final GuideStepSpec step;

  /// 进入主界面的回调，仅结束页使用。
  final VoidCallback onEnterApp;

  const GuideStepBody({
    super.key,
    required this.step,
    required this.onEnterApp,
  });

  @override
  Widget build(BuildContext context) {
    return switch (step.step) {
      GuideStep.workingMode => WorkingModeGuideBody(step: step),
      GuideStep.finish => FinishGuideBody(
        step: step,
        onEnterApp: onEnterApp,
      ),
      _ => PermissionGuideBody(step: step),
    };
  }
}