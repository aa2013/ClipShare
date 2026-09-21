import 'dart:async';

import 'package:clipshare/core/app_selection/local_app_info.dart';
import 'package:clipshare/core/utils/dialog.dart';
import 'package:clipshare/features/app_selection/pages/app_selection_page.dart';
import 'package:clipshare/features/app_selection/widgets/app_selection_form.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/routing/app_routes.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/models/dialog_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:go_router/go_router.dart';

/// 应用选择页路由参数。
///
/// 页面依赖外部提供的加载回调与选择回调，go_router 通过 extra 整体携带。
class AppSelectionRouteArgs {
  final bool distinguishSystemApps;
  final int limit;
  final Future<List<LocalAppInfo>> Function() loadAppInfos;
  final String Function(String devId) loadDeviceName;
  final Iterable<String>? selectedIds;
  final void Function(List<LocalAppInfo> selected) onSelectedDone;

  const AppSelectionRouteArgs({
    this.distinguishSystemApps = false,
    this.limit = -1,
    required this.loadAppInfos,
    required this.loadDeviceName,
    this.selectedIds,
    required this.onSelectedDone,
  });

  /// 按当前参数构建小屏应用选择页。
  AppSelectionPage buildPage() {
    return AppSelectionPage(
      distinguishSystemApps: distinguishSystemApps,
      limit: limit,
      loadAppInfos: loadAppInfos,
      loadDeviceName: loadDeviceName,
      selectedIds: selectedIds,
      onSelectedDone: onSelectedDone,
    );
  }
}

/// 打开应用选择入口。
///
/// 小屏下跳转到独立页面；大屏下以通用弹窗呈现，两者复用同一个 [AppSelectionForm]。
Future<void> showAppSelection(BuildContext context, AppSelectionRouteArgs args) async {
  if (context.isCompactScreen) {
    await context.pushNamed(
      AppRoutes.appSelection.name,
      extra: args,
    );
    return;
  }
  // 弹窗内确认按钮可点状态，随表单选中变化实时更新。
  final canConfirm = ValueNotifier<bool>(args.selectedIds?.isNotEmpty ?? false);
  final formKey = GlobalKey<AppSelectionFormState>();
  late final DialogController dialog;
  dialog = dialogManager.frame(
    context,
    icon: MdiIcons.listBoxOutline,
    title: TranslationKey.selectApplication.tr,
    // 表单自带滚动，避免弹窗再包一层滚动视图
    scrollable: false,
    // 确认后才由回调主动关闭，而非点击关闭按钮即关
    autoDismiss: false,
    content: AppSelectionForm(
      key: formKey,
      distinguishSystemApps: args.distinguishSystemApps,
      limit: args.limit,
      loadAppInfos: args.loadAppInfos,
      loadDeviceName: args.loadDeviceName,
      selectedIds: args.selectedIds,
      showSearchBar: true,
      canConfirmNotifier: canConfirm,
    ),
    actions: DialogActions(
      cancel: DialogAction(
        onPressed: () => dialog.close(),
      ),
      confirm: DialogAction(
        text: TranslationKey.confirm.tr,
        enabled: canConfirm,
        onPressed: () {
          final result = formKey.currentState?.buildResult() ?? const <LocalAppInfo>[];
          args.onSelectedDone(result);
          dialog.close();
        },
      ),
    ),
  );
  // 弹窗关闭后释放确认状态监听器。
  unawaited(dialog.future.whenComplete(() => canConfirm.dispose()));
}