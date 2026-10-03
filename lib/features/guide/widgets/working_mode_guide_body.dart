import 'package:clipshare/core/services/permission/permission_handler_facade.dart';
import 'package:clipshare/features/guide/models/guide_step.dart';
import 'package:clipshare/features/guide/widgets/guide_step_scaffold.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:flutter/material.dart';

/// 工作模式选择步骤的内容。
///
/// 当前为信息页：Shizuku / root / 忽略三选一的选择卡片尚未迁入，
/// 这里只保留说明与系统设置入口，因此该步骤不阻塞引导流程。
class WorkingModeGuideBody extends StatelessWidget {
  /// 步骤描述。
  final GuideStepSpec step;

  const WorkingModeGuideBody({
    super.key,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    return GuideStepScaffold(
      step: step,
      footer: TextButton.icon(
        // 工作模式依赖 Shizuku / root 等特权环境，统一引导到系统设置由用户自行确认。
        onPressed: openAppSettings,
        icon: const Icon(Icons.settings_outlined, color: Colors.blue),
        label: Text(TranslationKey.appSettings.tr),
      ),
    );
  }
}