import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/modules/sync_file_module/sync_file_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/pending_file_service.dart';
import 'package:clipshare/app/services/syncing_file_progress_service.dart';
import 'package:clipshare/app/utils/file_util.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/sync_file_status.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class SyncFilePage extends GetView<SyncFileController> {
  static const logTag = "SyncFilePage";
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final syncingFileService = Get.find<SyncingFileProgressService>();
  final pendingFileService = Get.find<PendingFileService>();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: controller.tabs.length,
      child: Scaffold(
        // backgroundColor: appConfig.bgColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: TabBar(
            controller: controller.tabController,
            tabs: [
              for (var tab in controller.tabs)
                Tab(
                  child: IntrinsicWidth(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(tab.name),
                        const SizedBox(
                          width: 5,
                        ),
                        tab.icon,
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        body: TabBarView(
          controller: controller.tabController,
          children: [
            RefreshIndicator(
              onRefresh: controller.refreshHistoryFiles,
              child: Obx(
                () => Visibility(
                  visible: controller.recHistories.isEmpty,
                  replacement: Stack(
                    children: [
                      ListView.builder(
                        itemCount: controller.recHistories.length,
                        itemBuilder: (context, i) {
                          var data = controller.recHistories[i];
                          final id = data.historyId!;
                          var selected = controller.selected.containsKey(id);
                          return Column(
                            children: [
                              InkWell(
                                child: controller.recHistories[i].copyWith(
                                  selectMode: controller.selectMode,
                                  selected: selected,
                                ),
                                onLongPress: () {
                                  controller.selected[id] = data;
                                  controller.selectMode = true;
                                  appConfig.enableMultiSelectionMode(
                                    controller: controller,
                                    selectionTips: TranslationKey.multiDelete.tr,
                                  );
                                },
                                onTap: () {
                                  if (controller.selected.containsKey(id)) {
                                    controller.selected.remove(id);
                                  } else {
                                    controller.selected[id] = data;
                                  }
                                },
                              ),
                              Visibility(
                                visible: i != controller.recHistories.length - 1,
                                child: const Divider(
                                  height: 0,
                                  indent: 10,
                                  endIndent: 10,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      //多选删除
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Row(
                          children: [
                            Visibility(
                              visible: controller.selectMode,
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.lightBlue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                margin: const EdgeInsets.only(right: 10),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      "${controller.selected.length} / ${controller.recHistories.length}",
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: appConfig.currentIsDarkMode ? Colors.white : Colors.black45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: controller.selectMode,
                              child: Tooltip(
                                message: TranslationKey.deselect.tr,
                                child: Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  child: FloatingActionButton(
                                    onPressed: () {
                                      controller.cancelSelectionMode();
                                      appConfig.disableMultiSelectionMode(true);
                                    },
                                    child: const Icon(Icons.close),
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: controller.selectMode,
                              child: Tooltip(
                                message: controller.selected.length == controller.recHistories.length ? TranslationKey.cancelSelectAll.tr : TranslationKey.selectAll.tr,
                                child: Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  child: FloatingActionButton(
                                    onPressed: () {
                                      final selectAll = controller.selected.length == controller.recHistories.length;
                                      if (selectAll) {
                                        controller.selected.clear();
                                      } else {
                                        final list = controller.recHistories.toList();
                                        var map = <int, SyncFileStatus>{};
                                        for (var item in list) {
                                          if (item.historyId != null) {
                                            map[item.historyId!] = item;
                                          }
                                        }
                                        controller.selected.addAll(map);
                                      }
                                    },
                                    child: Icon(
                                      controller.selected.length == controller.recHistories.length ? Icons.deselect : Icons.checklist,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: controller.selectMode && controller.selected.isNotEmpty,
                              child: Tooltip(
                                message: TranslationKey.delete.tr,
                                child: FloatingActionButton(
                                  onPressed: () {
                                    Global.showTipsDialog(
                                      context: context,
                                      text: TranslationKey.deleteWithFilesOnSyncFilePageAckDialogText.trParams({"length": controller.selected.length.toString()}),
                                      showCancel: true,
                                      showNeutral: true,
                                      neutralText: TranslationKey.deleteWithFiles.tr,
                                      okText: TranslationKey.onlyDeleteRecordsText.tr,
                                      autoDismiss: false,
                                      onOk: () async {
                                        await controller.deleteRecord(false);
                                        controller.selected.clear();
                                        controller.selectMode = false;
                                        appConfig.disableMultiSelectionMode(true);
                                      },
                                      onNeutral: () async {
                                        await controller.deleteRecord(true);
                                        controller.selected.clear();
                                        controller.selectMode = false;
                                        appConfig.disableMultiSelectionMode(true);
                                      },
                                      onCancel: () {
                                        Get.back();
                                      },
                                    );
                                  },
                                  child: const Icon(Icons.delete_forever),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [controller.emptyContent, ListView()],
                  ),
                ),
              ),
            ),
            Obx(
              () => Visibility(
                visible: controller.recList.isEmpty,
                replacement: ListView(
                  children: controller.recList,
                ),
                child: controller.emptyContent,
              ),
            ),
            Obx(
              () => Visibility(
                visible: controller.sendList.isEmpty,
                replacement: ListView(
                  children: controller.sendList,
                ),
                child: controller.emptyContent,
              ),
            ),
          ],
        ),
        floatingActionButton: Obx(
          () => Visibility(
            visible: pendingFileService.pendingItems.isEmpty && !appConfig.isEnableMultiSelectionMode,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20, right: 10),
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await FileUtil.pickFiles();
                  if (result.isEmpty) {
                    return;
                  }
                  final files = result.map((f) => DropItemFile(f.path!)).toList();
                  pendingFileService.addDropItems(files);
                  final homeController = Get.find<HomeController>();
                  homeController.showPendingItemsDetail.value = true;
                },
                tooltip: TranslationKey.addFilesFromSystem.tr,
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
