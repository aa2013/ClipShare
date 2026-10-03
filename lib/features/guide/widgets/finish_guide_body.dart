import 'package:clipshare/features/guide/models/guide_step.dart';
import 'package:clipshare/features/guide/widgets/guide_step_scaffold.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:flutter/material.dart';

/// 引导结束步骤的内容。
class FinishGuideBody extends StatelessWidget {
  /// 步骤描述。
  final GuideStepSpec step;

  /// 进入主界面的回调，由页面统一处理跳转与重复触发保护。
  final VoidCallback onEnterApp;

  const FinishGuideBody({
    super.key,
    required this.step,
    required this.onEnterApp,
  });

  @override
  Widget build(BuildContext context) {
    return GuideStepScaffold(
      step: step,
      footer: TextButton.icon(
        onPressed: onEnterApp,
        icon: const Icon(Icons.arrow_circle_right, color: Colors.blue),
        label: Text(TranslationKey.enterSoftware.tr),
      ),
    );
  }
}