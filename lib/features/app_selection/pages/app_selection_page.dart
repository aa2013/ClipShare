import 'package:clipshare/core/app_selection/local_app_info.dart';
import 'package:clipshare/features/app_selection/widgets/app_selection_form.dart';
import 'package:clipshare/features/app_selection/widgets/app_selection_search_bar.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

/// 应用选择页：标题栏承载搜索与确认，列表内容复用 [AppSelectionForm]。
///
/// 小屏由路由打开的独立页面；大屏不走此页，改由 [AppSelectionForm] 以弹窗呈现。
class AppSelectionPage extends StatefulWidget {
  final bool distinguishSystemApps;
  final int limit;
  final Future<List<LocalAppInfo>> Function() loadAppInfos;
  final String Function(String devId) loadDeviceName;
  final Iterable<String>? selectedIds;
  final void Function(List<LocalAppInfo> selected) onSelectedDone;

  const AppSelectionPage({
    super.key,
    this.distinguishSystemApps = false,
    required this.limit,
    required this.loadAppInfos,
    required this.loadDeviceName,
    this.selectedIds,
    required this.onSelectedDone,
  });

  @override
  State<AppSelectionPage> createState() => _AppSelectionPageState();
}

class _AppSelectionPageState extends State<AppSelectionPage> {
  final _formKey = GlobalKey<AppSelectionFormState>();

  /// 确认按钮可点状态，由表单选中变化同步更新。
  late final ValueNotifier<bool> _canConfirm = ValueNotifier(widget.selectedIds?.isNotEmpty ?? false);

  @override
  void dispose() {
    _canConfirm.dispose();
    super.dispose();
  }

  /// 提取选中结果回传外部后关闭页面。
  void _confirm() {
    final result = _formKey.currentState?.buildResult() ?? const <LocalAppInfo>[];
    widget.onSelectedDone(result);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 10),
            const Icon(MdiIcons.listBoxOutline),
            const SizedBox(width: 5),
            Expanded(
              child: AppSelectionSearchBar(
                placeholder: TranslationKey.selectApplication.tr,
                onSearchChanged: (keyword) => _formKey.currentState?.applySearch(keyword),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: TranslationKey.confirm.tr,
              child: ValueListenableBuilder<bool>(
                valueListenable: _canConfirm,
                builder: (context, enabled, _) => IconButton(
                  onPressed: enabled ? _confirm : null,
                  icon: const Icon(Icons.check),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: AppSelectionForm(
          key: _formKey,
          distinguishSystemApps: widget.distinguishSystemApps,
          limit: widget.limit,
          loadAppInfos: widget.loadAppInfos,
          loadDeviceName: widget.loadDeviceName,
          selectedIds: widget.selectedIds,
          canConfirmNotifier: _canConfirm,
        ),
      ),
    );
  }
}