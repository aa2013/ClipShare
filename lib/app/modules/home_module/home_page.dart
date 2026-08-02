import 'dart:io';
import 'dart:math';

import 'package:clipshare/app/data/models/keyboard_shortcut.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/modules/sync_file_module/sync_file_controller.dart';
import 'package:clipshare/app/modules/views/drag_and_send_file_page.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/history_sync_progress_service.dart';
import 'package:clipshare/app/services/pending_file_service.dart';
import 'package:clipshare/app/services/transport/socket_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/base/custom_keyboard_listener.dart';
import 'package:clipshare/app/widgets/base/multi_drawer.dart';
import 'package:clipshare/app/widgets/base/my_navigation_rail.dart';
import 'package:clipshare/app/widgets/blur_background.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:clipshare/app/widgets/drag_file_mask.dart';
import 'package:clipshare/app/widgets/filter/history_filter.dart';
import 'package:clipshare/app/widgets/loading_dots.dart';
import 'package:clipshare/app/widgets/native_file_drop_region.dart';
import 'package:clipshare/app/widgets/segment_text_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../sync_file_module/sync_file_page.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class HomePage extends GetView<HomeController> {
  final appConfig = Get.find<ConfigService>();
  final sktService = Get.find<SocketService>();
  final androidChannelService = Get.find<AndroidChannelService>();
  final syncFileController = Get.find<SyncFileController>();
  final pendingFileService = Get.find<PendingFileService>();

  GetxController get currentPageController => controller.currentPageController;

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    if (controller.screenWidth != screenWidth) {
      controller.screenWidth = screenWidth;
    }
    final currentTheme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (appConfig.isMultiSelectionMode(currentPageController)) {
          appConfig.disableMultiSelectionMode(true);
          controller.notifyMultiSelectionPopScopeDisable();
          return;
        }
        if (Platform.isAndroid && !controller.showPendingItemsDetail.value) {
          androidChannelService.moveToBg();
        }
      },
      child: CustomKeyboardListener(
        shortcuts: [
          KeyboardShortcut(
            physicalKeys: {PhysicalKeyboardKey.escape},
            onTrigger: controller.handleEscapeShortcut,
          ),
        ],
        child: Obx(
          () => NativeFileDropRegion(
            onDragEntered: () {
              controller.dragging.value = true;
              syncFileController.tabController.index = 2;
            },
            onDragExited: () {
              controller.dragging.value = false;
            },
            onDropDone: (files) {
              final syncFilePageIndex = controller.pages.indexWhere((item) => item is SyncFilePage);
              controller.index = syncFilePageIndex;
              controller.showPendingItemsDetail.value = true;
              pendingFileService.addDropItems(files);
            },
            child: Stack(
              children: [
              Obx(
                () => Scaffold(
                  key: controller.homeScaffoldKey,
                  appBar: !controller.isBigScreen
                      ? AppBar(
                          title: Obx(() {
                            if (controller.showingHistorySearch.value && controller.isHistoryPage) {
                              return _buildHistorySearchAppBar();
                            }
                            return Row(
                            children: [
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Obx(
                                      () => ConditionWidget(
                                        //todo 是否会有问题？
                                        visible: appConfig.isMultiSelectionMode(currentPageController),
                                        replacement: controller.bottomNavBarItems[controller.index].icon,
                                        child: const Icon(Icons.checklist),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Obx(
                                      () {
                                        final syncProgressService = Get.find<HistorySyncProgressService>();
                                        final selectionMode = appConfig.isMultiSelectionMode(currentPageController);
                                        final pageTitle = controller.bottomNavBarItems[controller.index].label!;
                                        final selectionText = TranslationKey.multipleChoiceOperationAppBarTitle.tr;
                                        bool isSyncing = syncProgressService.syncing;
                                        final icon = controller.bottomNavBarItems[controller.index].icon;
                                        bool isHistoryPage = icon is Icon && icon.icon == Icons.history;
                                        if (!selectionMode && isSyncing && isHistoryPage) {
                                          int total = syncProgressService.total;
                                          int syncedCnt = syncProgressService.syncedCnt;
                                          return LoadingDots(text: Text("${TranslationKey.homeAppBarSyncingProgressText.tr}($syncedCnt/$total)"));
                                        }
                                        return Text(selectionMode ? selectionText : pageTitle,style: const TextStyle(fontSize: 20),);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            );
                          }),
                          actions: _buildSmallScreenAppBarActions(),
                          automaticallyImplyLeading: false,
                        )
                      : null,
                  body: Row(
                    children: [
                      if(controller.isBigScreen)
                        Obx((){
                         final widget = MyNavigationRail(
                           extended: controller.leftMenuExtend.value,
                           onSelected: (i) {
                             controller.index = i;
                           },
                           minExtendedWidth: 200,
                           items: controller.leftBarItems,
                           selectedIndex: controller.index,
                           trailing: Expanded(
                             child: Align(
                               alignment: Alignment.bottomCenter,
                               child: Padding(
                                 padding: const EdgeInsets.only(bottom: 10),
                                 child: IconButton(
                                   icon: Icon(
                                     controller.leftMenuExtend.value ? Icons.keyboard_double_arrow_left_outlined : Icons.keyboard_double_arrow_right_outlined,
                                     color: Colors.blueGrey,
                                   ),
                                   onPressed: () {
                                     controller.leftMenuExtend.value = !controller.leftMenuExtend.value;
                                   },
                                 ),
                               ),
                             ),
                           ),
                         );
                         if(Platform.isMacOS){
                           return Padding(
                             padding: Constants.macOSSafeAreaHeight.insetT,
                             child: widget,
                           );
                         }
                         return widget;
                        }),
                      Expanded(
                        child: Obx(
                          () => IndexedStack(
                            index: controller.index,
                            children: controller.pages,
                          ),
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar: !controller.isBigScreen
                      ? Obx(
                          () => BottomNavigationBar(
                            type: BottomNavigationBarType.fixed,
                            backgroundColor: currentTheme.bottomNavigationBarTheme.backgroundColor ?? currentTheme.colorScheme.surface,
                            selectedItemColor: currentTheme.bottomNavigationBarTheme.selectedItemColor,
                            unselectedItemColor: currentTheme.bottomNavigationBarTheme.unselectedItemColor,
                            currentIndex: controller.index,
                            onTap: (i) => controller.index = i,
                            items: controller.bottomNavBarItems,
                          ),
                        )
                      : null,
                ),
              ),
              Obx(
              () => Visibility(
                visible: controller.dragging.value && !controller.showPendingItemsDetail.value,
                child: Positioned.fill(
                  child: BlurBackground(
                    child: DragFileMask(
                      onClose: () {
                        controller.dragging.value = false;
                      },
                    ),
                  ),
                ),
              ),
            ),
            Obx(
              () => Visibility(
                visible: controller.showPendingItemsDetail.value,
                child: ClipRRect(
                  child: BlurBackground(
                    child: DragAndSendFilePage(
                      onItemRemove: (item) {
                        pendingFileService.removeDropItem(item);
                      },
                    ),
                  ),
                ),
              ),
            ),
            Visibility(
              visible: controller.showPendingItemsDetail.value || (controller.isSyncFilePage && pendingFileService.pendingItems.isNotEmpty),
              child: Positioned(
                right: 30,
                bottom: 30,
                child: Row(
                  children: [
                    Obx(
                      () => Visibility(
                        visible: pendingFileService.pendingItems.isNotEmpty && controller.showPendingItemsDetail.value,
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          child: FloatingActionButton(
                            tooltip: TranslationKey.sendFiles.tr,
                            onPressed: () async {
                              final devices = pendingFileService.pendingDevs;
                              if (devices.isEmpty) {
                                Global.showTipsDialog(context: context, text: TranslationKey.pleaseSelectDevices.tr);
                                return;
                              }
                              await pendingFileService.sendPendingFiles();
                              controller.showPendingItemsDetail.value = false;
                              pendingFileService.clearPendingInfo();
                              Global.showSnackBarSuc(
                                text: TranslationKey.startSendFileToast.tr,
                                context: context,
                              );
                            },
                            child: Transform.rotate(
                              angle: -45 * (pi / 180),
                              child: const Icon(Icons.send),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Obx(
                      () => FloatingActionButton(
                        onPressed: () {
                          controller.showPendingItemsDetail.value = !controller.showPendingItemsDetail.value;
                        },
                        tooltip: controller.showPendingItemsDetail.value ? "${TranslationKey.close.tr}${PlatformExt.isDesktop ? '(ESC)' : ""}" : TranslationKey.viewPendingFiles.tr,
                        child: Icon(controller.showPendingItemsDetail.value ? Icons.close : Icons.file_open_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Obx(
              () => Visibility(
                visible: controller.isSegmenting.value,
                child: Positioned.fill(
                  child: BlurBackground(
                    child: SegmentTestView(
                      text: controller.segmentText.value,
                      onClose: () {
                        controller.isSegmenting.value = false;
                        controller.segmentText.value = '';
                      },
                    ),
                  ),
                ),
              ),
            ),
              Obx(() => MultiDrawer(controller: controller.drawer, width: controller.drawerWidth)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSmallScreenAppBarActions() {
    return [
      Obx(
        () {
          if (!controller.isHistoryPage || controller.showingHistorySearch.value) {
            return const SizedBox.shrink();
          }
          final historyController = Get.find<HistoryController>();
          if (historyController.filterLoading.value) {
            return const SizedBox.shrink();
          }
          return IconButton(
            tooltip: TranslationKey.search.tr,
            onPressed: _showHistorySearch,
            icon: const Icon(Icons.search_rounded),
          );
        },
      ),
    ];
  }

  Widget _buildHistorySearchAppBar() {
    final historyController = Get.find<HistoryController>();
    final filterController = historyController.filterController;
    return _HistorySearchAppBar(
      controller: filterController,
      onFocusLost: () {
        controller.showingHistorySearch.value = false;
      },
    );
  }

  void _showHistorySearch() {
    final historyController = Get.find<HistoryController>();
    if (historyController.filterLoading.value) {
      return;
    }
    controller.showingHistorySearch.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      historyController.filterController.focusNode.requestFocus();
    });
  }
}

class _HistorySearchAppBar extends StatefulWidget {
  final HistoryFilterController controller;
  final VoidCallback onFocusLost;

  const _HistorySearchAppBar({
    required this.controller,
    required this.onFocusLost,
  });

  @override
  State<_HistorySearchAppBar> createState() => _HistorySearchAppBarState();
}

class _HistorySearchAppBarState extends State<_HistorySearchAppBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _HistorySearchAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.focusNode.removeListener(_onFocusChanged);
    widget.controller.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (!widget.controller.focusNode.hasFocus) {
      widget.onFocusLost();
    }
  }

  @override
  Widget build(BuildContext context) {
    return HistoryFilterSearchRow(
      controller: widget.controller,
      showFillColor: false,
    );
  }
}
