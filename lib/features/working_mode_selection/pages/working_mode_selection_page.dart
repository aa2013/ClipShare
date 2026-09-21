import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/runtime/app_state/app_state_provider.dart';
import 'package:clipshare/core/services/clipboard/clipboard_service_provider.dart';
import 'package:clipshare/core/settings/clipboard/clipboard_settings_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/widgets/env/environment_selections.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 工作模式切换页。
///
/// 选择期间挂起剪贴板监听的自动启动：Shizuku / root 授权成功后不立即起监听，
/// 只有点「确定」才让监听跟随新工作模式；直接返回则配置与监听都保持原状。
class WorkingModeSelectionPage extends ConsumerStatefulWidget {
  const WorkingModeSelectionPage({super.key});

  @override
  ConsumerState<WorkingModeSelectionPage> createState() => _WorkingModeSelectionPageState();
}

class _WorkingModeSelectionPageState extends ConsumerState<WorkingModeSelectionPage> {
  /// 内容区上下留白。
  static const double _contentPadding = 20;

  /// 操作按钮行的右侧留白。
  static const double _actionPadding = 30;

  /// 取消与确定按钮的间距。
  static const double _actionGap = 10;

  /// 运行时配置入口，dispose 阶段仍需用它复位「正在选择工作模式」标记。
  late final AppStateNotifier _appState;

  /// 当前选中的工作模式，进入页面时预选已配置的模式。
  EnvironmentType? _selected;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(clipboardSettingsProvider).value?.workingMode;
    _appState = ref.read(appStateProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_){
      _appState.updateSelectingWorkingMode(true);
    });
  }

  @override
  void dispose() {
    _appState.updateSelectingWorkingMode(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          TranslationKey.selectWorkMode.tr,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.blueGrey,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: _contentPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EnvironmentSelections(
                selected: _selected,
                onSelected: _onSelected,
              ),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  /// 记录本次选择，确定按钮据此决定是否可用。
  void _onSelected(EnvironmentType? selected) {
    setState(() {
      _selected = selected;
    });
  }

  /// 取消与确定按钮行。
  Widget _buildActions() {
    final confirmable = _selected != null;
    return Padding(
      padding: const EdgeInsets.only(right: _actionPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: context.pop,
            child: Text(
              TranslationKey.dialogCancelText.tr,
              style: const TextStyle(color: Colors.blue),
            ),
          ),
          const SizedBox(width: _actionGap),
          TextButton(
            onPressed: confirmable ? _confirm : null,
            child: Text(
              TranslationKey.dialogConfirmText.tr,
              style: confirmable ? const TextStyle(color: Colors.blue) : null,
            ),
          ),
        ],
      ),
    );
  }

  /// 落库并让剪贴板监听跟随确认后的工作模式，完成后返回来源页。
  Future<void> _confirm() async {
    final selected = _selected;
    if (selected == null) {
      return;
    }
    final configDao = ref.read(appDbProvider).requireValue.configDao;
    await configDao.addOrUpdate(ConfigKey.workingMode, selected.name);
    ref.invalidate(clipboardSettingsProvider);
    await _applyListening(selected);
    if (mounted) {
      context.pop();
    }
  }

  /// 忽略模式停止监听；特权环境按最新配置重启监听。
  Future<void> _applyListening(EnvironmentType selected) async {
    if (selected == EnvironmentType.none) {
      await clipboardManager.stopListening();
      return;
    }
    final clipboardService = await ref.read(clipboardServiceProvider.future);
    await clipboardService.restartAndroidListening();
  }
}