import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/extensions/context_extension.dart';
import 'package:clipshare/core/providers/desktop/multi_window/multi_window_args_provider.dart';
import 'package:clipshare/core/providers/desktop/multi_window/multi_window_config_provider.dart';
import 'package:clipshare/core/providers/desktop/window_control/window_control_provider.dart';
import 'package:clipshare/shared/enums/multi_window/multi_window_tag.dart';
import 'package:clipshare/shared/widgets/layouts/platform_title_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

class ClipShareTitleBarLayout extends ConsumerWidget {
  final List<Widget> title;
  final Widget child;
  static const double windowsTitleBarHeight = 35;
  static const double defaultTitleBarHeight = 25;

  const ClipShareTitleBarLayout({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windowControl = ref.watch(windowControlProvider);
    final windowControlNotifier = ref.read(windowControlProvider.notifier);
    final titleLayout = Row(children: title);
    Widget body;
    if ((context.isLandscape || !context.isCompactScreen) && isMobile) {
      body = Scaffold(
        body: SafeArea(child: child),
      );
    } else {
      body = child;
    }
    return Column(
      children: [
        Visibility(
          visible: isDesktop && !isMacOS,
          child: SizedBox(
            height: ClipShareTitleBarLayout.windowsTitleBarHeight,
            // 这里若使用 Container 而不是 Material 会导致窗体自定义按钮的悬浮背景色失效（内部的inkwell依赖于 Material 组件）
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: (details) {
                        windowManager.startDragging();
                      },
                      onDoubleTap: () {
                        if (windowControl.maxWindow) {
                          windowControlNotifier.unMaximize();
                        } else {
                          windowControlNotifier.maximize();
                        }
                      },
                      child: titleLayout,
                    ),
                  ),
                  Visibility(
                    visible: windowControl.resizable,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Visibility(
                          visible: windowControl.minimizable,
                          child: PlatformTitleButton(
                            onTap: windowControlNotifier.minimize,
                            icon: MdiIcons.minus,
                            size: isWindows ? ClipShareTitleBarLayout.windowsTitleBarHeight : 25,
                          ),
                        ),
                        //最小化与右边的间隔
                        if (isLinux)
                          Visibility(
                            visible: windowControl.minimizable,
                            child: const SizedBox(width: 5),
                          ),
                        Visibility(
                          visible: windowControl.maximizable || windowControl.minimizable,
                          child: PlatformTitleButton(
                            onTap: windowControl.maximizable
                                ? () {
                                    if (windowControl.maxWindow) {
                                      windowControlNotifier.unMaximize();
                                    } else {
                                      windowControlNotifier.maximize();
                                    }
                                  }
                                : null,
                            icon: windowControl.maxWindow && windowControl.maximizable
                                ? MdiIcons.cardMultipleOutline
                                : Icons.check_box_outline_blank,
                            iconColor: windowControl.maximizable ? null : Colors.grey,
                            size: isWindows ? ClipShareTitleBarLayout.windowsTitleBarHeight : 25,
                          ),
                        ),
                        //最大化与右边的间隔
                        if (isLinux)
                          Visibility(
                            visible: windowControl.maximizable || windowControl.minimizable,
                            child: const SizedBox(width: 5),
                          ),
                      ],
                    ),
                  ),
                  _buildPinWidget(ref, windowControl.historyPopupPinned, windowControlNotifier),
                  Visibility(
                    visible: windowControl.closeable,
                    child: PlatformTitleButton(
                      onTap: () => windowControlNotifier.close(true),
                      icon: Icons.close,
                      size: isWindows ? ClipShareTitleBarLayout.windowsTitleBarHeight : 25,
                      hoverColor: isWindows ? Colors.red : null,
                      hoveredIconColor: isWindows ? Colors.white : null,
                    ),
                  ),
                  if (isLinux) const SizedBox(width: 5),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  /// 历史子弹窗在开启失焦关闭时显示固定按钮。
  Widget _buildPinWidget(
    WidgetRef ref,
    bool historyPopupPinned,
    WindowControlNotifier windowControlNotifier,
  ) {
    final multiWindowArgs = ref.watch(multiWindowArgsProvider);
    final multiWindowConfig = ref.watch(multiWindowConfigProvider);
    final isHistoryWindow = multiWindowArgs?.tag == MultiWindowTag.history;
    final showHistoryPopupPin = multiWindowConfig.enabled
        && isHistoryWindow
        && multiWindowConfig.autoClosePopupOnBlur;
    if (!showHistoryPopupPin) {
      return const SizedBox.shrink();
    }
    return PlatformTitleButton(
      onTap: () {
        windowControlNotifier.setHistoryPopupPinned(!historyPopupPinned);
      },
      icon: MdiIcons.pin,
      iconColor: historyPopupPinned ? Colors.blue : Colors.grey,
      size: isWindows ? windowsTitleBarHeight : defaultTitleBarHeight,
    );
  }
}
