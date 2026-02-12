import 'dart:io';

import 'package:clipshare/app/services/window_control_service.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/widgets/base/platform_title_button.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:window_manager/window_manager.dart';

class CustomTitleBarLayout extends StatefulWidget {
  final List<Widget> children;
  final Widget child;
  static const double titleBarHeight = 35;

  const CustomTitleBarLayout({
    super.key,
    required this.children,
    required this.child,
  });

  @override
  State<StatefulWidget> createState() => _CustomTitleBarLayoutState();
}

class _CustomTitleBarLayoutState extends State<CustomTitleBarLayout> {
  final windowControlService = Get.find<WindowControlService>();
  bool closeBtnHovered = false;

  @override
  Widget build(BuildContext context) {
    final titleLayout = Row(
      children: widget.children,
    );
    return Column(
      children: [
        Visibility(
          visible: PlatformExt.isDesktop && !Platform.isMacOS,
          child: SizedBox(
            height: CustomTitleBarLayout.titleBarHeight,
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
                        if (windowControlService.maxWindow.value) {
                          windowControlService.unMaximize();
                        } else {
                          windowControlService.maximize();
                        }
                      },
                      child: titleLayout,
                    ),
                  ),
                  Obx(
                    () => Visibility(
                      visible: windowControlService.resizable.value,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Obx(
                            () => Visibility(
                              visible: windowControlService.minimizable.value,
                              child: PlatformTitleButton(
                                onTap: windowControlService.minimize,
                                icon: MdiIcons.minus,
                                size: Platform.isWindows
                                    ? CustomTitleBarLayout.titleBarHeight
                                    : 25,
                              ),
                            ),
                          ),
                          //最小化与右边的间隔
                          if(Platform.isLinux)
                            Obx(
                               () => Visibility(
                                 visible: windowControlService.minimizable.value,
                                 child: const SizedBox(width: 5),
                               ),
                            ),
                          Obx(
                            () => Visibility(
                              visible: windowControlService.maximizable.value || windowControlService.minimizable.value,
                              child: PlatformTitleButton(
                                onTap: windowControlService.maximizable.value ? () {
                                  if (windowControlService.maxWindow.value) {
                                    windowControlService.unMaximize();
                                  } else {
                                    windowControlService.maximize();
                                  }
                                } : null,
                                icon: windowControlService.maxWindow.value &&
                                    windowControlService.maximizable.value
                                    ? MdiIcons.cardMultipleOutline
                                    : Icons.check_box_outline_blank,
                                iconColor: windowControlService.maximizable.value
                                    ? null
                                    : Colors.grey,
                                size: Platform.isWindows
                                    ? CustomTitleBarLayout.titleBarHeight
                                    : 25,
                              ),
                            ),
                          ),
                          //最大化与右边的间隔
                          if(Platform.isLinux)
                            Obx(
                              () => Visibility(
                                visible: windowControlService.maximizable.value || windowControlService.minimizable.value,
                                child: const SizedBox(width: 5),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Obx(
                    () => Visibility(
                      visible: windowControlService.closeable.value,
                      child:
                      PlatformTitleButton(
                        onTap: () => windowControlService.close(true),
                        icon: Icons.close,
                        size: Platform.isWindows
                            ? CustomTitleBarLayout.titleBarHeight
                            : 25,
                        hoverColor: Platform.isWindows ? Colors.red : null,
                        hoveredIconColor: Platform.isWindows ? Colors.white : null,
                      ),
                    ),
                  ),
                  if(Platform.isLinux)
                    const SizedBox(width: 5)
                ],
              ),
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
