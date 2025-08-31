import 'package:clipshare/app/services/window_control_service.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
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
          visible: PlatformExt.isDesktop,
          child: SizedBox(
            height: CustomTitleBarLayout.titleBarHeight,
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
                            child: InkWell(
                              mouseCursor: SystemMouseCursors.basic,
                              child: SizedBox(
                                width: CustomTitleBarLayout.titleBarHeight,
                                height: CustomTitleBarLayout.titleBarHeight,
                                child: Icon(
                                  MdiIcons.minus,
                                  size: 15,
                                ),
                              ),
                              onTap: () {
                                windowControlService.minimize();
                              },
                            ),
                          ),
                        ),
                        Obx(
                          () => Visibility(
                            visible: windowControlService.maximizable.value || windowControlService.minimizable.value,
                            child: InkWell(
                              mouseCursor: SystemMouseCursors.basic,
                              onTap: windowControlService.maximizable.value
                                  ? () {
                                      if (windowControlService.maxWindow.value) {
                                        windowControlService.unMaximize();
                                      } else {
                                        windowControlService.maximize();
                                      }
                                    }
                                  : null,
                              child: SizedBox(
                                width: CustomTitleBarLayout.titleBarHeight,
                                height: CustomTitleBarLayout.titleBarHeight,
                                child: Icon(
                                  windowControlService.maxWindow.value && windowControlService.maximizable.value ? MdiIcons.cardMultipleOutline : Icons.check_box_outline_blank,
                                  size: 13,
                                  color: windowControlService.maximizable.value ? null : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Obx(
                  () => Visibility(
                    visible: windowControlService.closeable.value,
                    child: InkWell(
                      mouseCursor: SystemMouseCursors.basic,
                      hoverColor: Colors.red,
                      splashColor: Colors.red,
                      highlightColor: Colors.red,
                      onHover: (hovered) {
                        setState(() {
                          closeBtnHovered = hovered;
                        });
                      },
                      child: SizedBox(
                        width: CustomTitleBarLayout.titleBarHeight,
                        height: CustomTitleBarLayout.titleBarHeight,
                        child: Icon(
                          Icons.close,
                          size: 13,
                          color: closeBtnHovered ? Colors.white : null,
                        ),
                      ),
                      onTap: () {
                        windowControlService.close(true);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
