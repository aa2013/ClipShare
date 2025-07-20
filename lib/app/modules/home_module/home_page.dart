import 'dart:io';
import 'dart:math';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/modules/sync_file_module/sync_file_controller.dart';
import 'package:clipshare/app/modules/views/drag_and_send_file_page.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/pending_file_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/blur_background.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:clipshare/app/widgets/drag_file_mask.dart';
import 'package:clipshare/app/widgets/loading_dots.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
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
    controller.screenWidth = MediaQuery.of(context).size.width;
    final currentTheme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (appConfig.isMultiSelectionMode(currentPageController)) {
          appConfig.disableMultiSelectionMode(true);
          controller.notifyMultiSelectionPopScopeDisable();
          return;
        }
        if (Platform.isAndroid) {
          androidChannelService.moveToBg();
        }
      },
      child: Obx(
        () => Stack(
          children: [
            DropTarget(
              child: Obx(
                () => Scaffold(
                  key: controller.homeScaffoldKey,
                  // backgroundColor: appConfig.bgColor,
                  appBar: !controller.isBigScreen
                      ? AppBar(
                          backgroundColor: currentTheme.colorScheme.inversePrimary,
                          title: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Obx(
                                      () => ConditionWidget(
                                        //todo 是否会有问题？
                                        visible: appConfig.isMultiSelectionMode(currentPageController),
                                        child: const Icon(Icons.checklist),
                                        replacement: controller.navBarItems[controller.index].icon,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Obx(
                                      () {
                                        final selectionMode = appConfig.isMultiSelectionMode(currentPageController);
                                        final pageTitle = controller.navBarItems[controller.index].label!;
                                        final selectionText = appConfig.multiSelectionText;
                                        bool isSyncing = appConfig.isHistorySyncing.value;
                                        final icon = controller.navBarItems[controller.index].icon;
                                        bool isHistoryPage = icon is Icon && icon.icon == Icons.history;
                                        if (!selectionMode && isSyncing && isHistoryPage) {
                                          final progresses = sktService.missingDataSyncProgress.values;
                                          int total = 0;
                                          int syncedCnt = 0;
                                          for (var progress in progresses) {
                                            total += progress.total;
                                            syncedCnt += progress.syncedCount;
                                          }
                                          return LoadingDots(
                                            text: Text(
                                              "${TranslationKey.homeAppBarSyncingProgressText.tr}($syncedCnt/$total)",
                                            ),
                                          );
                                        }
                                        return Text(
                                          selectionMode ? selectionText : pageTitle,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Obx(
                                () => Visibility(
                                  visible: !appConfig.isMultiSelectionMode(currentPageController),
                                  child: IconButton(
                                    onPressed: () {
                                      //导航至搜索页面
                                      controller.gotoSearchPage(null, null);
                                    },
                                    tooltip: TranslationKey.search.tr,
                                    icon: const Icon(
                                      Icons.search_rounded,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          automaticallyImplyLeading: false,
                        )
                      : null,
                  body: Row(
                    children: [
                      controller.isBigScreen
                          ? Obx(
                              () => NavigationRail(
                                leading: controller.leftMenuExtend.value
                                    ? Row(
                                        children: [
                                          controller.logoImg,
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          const Text(Constants.appName),
                                        ],
                                      )
                                    : controller.logoImg,
                                extended: controller.leftMenuExtend.value,
                                onDestinationSelected: (i) {
                                  controller.index = i;
                                },
                                minExtendedWidth: 200,
                                destinations: controller.leftBarItems,
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
                              ),
                            )
                          : const SizedBox.shrink(),
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
                            backgroundColor: currentTheme.colorScheme.surface,
                            currentIndex: controller.index,
                            onTap: (i) => controller.index = i,
                            items: controller.navBarItems,
                          ),
                        )
                      : null,
                  endDrawer: controller.isBigScreen
                      ? SizedBox(
                          width: controller.drawerWidth,
                          child: controller.drawer,
                        )
                      : null,
                  onEndDrawerChanged: (isOpened) {
                    if (isOpened) {
                      return;
                    }
                    controller.onEndDrawerClosed?.call();
                  },
                ),
              ),
              onDragEntered: (detail) {
                controller.dragging.value = true;
                syncFileController.tabController.index = 2;
              },
              onDragExited: (detail) {
                controller.dragging.value = false;
              },
              onDragDone: (detail) {
                final syncFilePageIndex = controller.pages.indexWhere((item) => item is SyncFilePage);
                controller.index = syncFilePageIndex;
                controller.showPendingItemsDetail.value = true;
                pendingFileService.addDropItems(detail.files);
              },
            ),
            Obx(
              () => Visibility(
                visible: controller.dragging.value && !controller.showPendingItemsDetail.value,
                child: const Positioned.fill(
                  child: BlurBackground(
                    child: DragFileMask(),
                  ),
                ),
              ),
            ),
            Obx(
              () => Visibility(
                visible: controller.showPendingItemsDetail.value,
                child: Positioned.fill(
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
          ],
        ),
      ),
    );
  }
}
