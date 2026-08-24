import 'package:clipshare/core/app_selection/local_app_info.dart';
import 'package:clipshare/core/utils/dialog.dart';
import 'package:clipshare/features/app_selection/pages/app_selection_page.dart';
import 'package:clipshare/routing/app_routes.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:flutter/material.dart';
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

  /// 按当前参数构建应用选择页。
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
/// 小屏下跳转到独立页面；大屏下以通用弹窗呈现，两者复用同一个 [AppSelectionPage]。
Future<void> showAppSelection(BuildContext context, AppSelectionRouteArgs args) async {
  if (context.isCompactScreen) {
    await context.pushNamed(
      AppRoutes.appSelection.name,
      extra: args,
    );
    return;
  }
  //todo 原使用 DynamicSizeWidget 约束来源选择弹窗尺寸，待新弹窗容器替代。
  dialogManager.open(context, args.buildPage());
}
