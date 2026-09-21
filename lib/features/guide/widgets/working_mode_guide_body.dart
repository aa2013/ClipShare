import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/settings/clipboard/clipboard_settings_provider.dart';
import 'package:clipshare/features/guide/models/guide_step.dart';
import 'package:clipshare/features/guide/providers/guide_controller_provider.dart';
import 'package:clipshare/features/guide/widgets/guide_step_scaffold.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/widgets/env/environment_selections.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 工作模式选择步骤的内容。
///
/// 选择结果持久化为工作模式配置，步骤完成状态由引导控制器按处理器重新判定，
/// 与其余步骤共用同一份判定来源。
class WorkingModeGuideBody extends ConsumerWidget {
  /// 步骤描述。
  final GuideStepSpec step;

  const WorkingModeGuideBody({
    super.key,
    required this.step,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workingMode = ref
        .watch(clipboardSettingsProvider)
        .requireValue
        .workingMode;
    final completed = ref.watch(
      guideControllerProvider.select(
        (state) => state.isCompleted(GuideStep.workingMode),
      ),
    );
    return GuideStepScaffold(
      step: step,
      footer: EnvironmentSelections(
        // 尚未选择时配置默认值同样落在 none，需借助完成状态区分「尚未选择」与「主动忽略」
        selected: completed ? workingMode : null,
        onSelected: (selected) => _onSelected(ref, selected),
      ),
    );
  }

  /// 持久化选定的工作模式，并重新判定本步骤是否完成。
  ///
  /// 写库必须先于重新判定，否则处理器读到的仍是旧配置，步骤会停留在未完成状态。
  Future<void> _onSelected(WidgetRef ref, EnvironmentType? selected) async {
    final configDao = ref.read(appDbProvider).requireValue.configDao;
    await configDao.addOrUpdate(
      ConfigKey.workingMode,
      (selected ?? EnvironmentType.none).name,
    );
    ref.invalidate(clipboardSettingsProvider);
    await ref.read(guideControllerProvider.notifier).refreshCurrent();
  }
}
