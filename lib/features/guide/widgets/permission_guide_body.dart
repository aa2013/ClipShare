import 'package:clipshare/features/guide/models/guide_step.dart';
import 'package:clipshare/features/guide/providers/guide_controller_provider.dart';
import 'package:clipshare/features/guide/providers/guide_step_handler_provider.dart';
import 'package:clipshare/features/guide/widgets/guide_step_scaffold.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 权限类引导步骤的内容。
///
/// 完成状态统一来自 [guideControllerProvider]，授权动作交给步骤对应的权限处理器，
/// 本组件只负责展示与触发。
class PermissionGuideBody extends ConsumerWidget {
  /// 步骤描述。
  final GuideStepSpec step;

  const PermissionGuideBody({
    super.key,
    required this.step,
  });

  /// 已完成时展示的图标。
  static const IconData _completedIcon = Icons.check_circle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = ref.watch(
      guideControllerProvider.select(
        (state) => state.isCompleted(step.step),
      ),
    );
    final handler = ref.watch(guideStepHandlerProvider(step.step)).asData?.value;
    return GuideStepScaffold(
      step: step,
      footer: TextButton.icon(
        // 已授权后不再重复拉起授权入口。
        onPressed: completed ? null : () => handler?.request(context),
        icon: completed
            ? const Icon(_completedIcon, color: Colors.blue)
            : const SizedBox.shrink(),
        label: Text(
          completed ? TranslationKey.done.tr : TranslationKey.goAuthorize.tr,
        ),
      ),
    );
  }
}