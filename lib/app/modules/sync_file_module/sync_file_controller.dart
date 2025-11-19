import 'dart:io';

import 'package:clipshare/app/data/enums/syncing_file_state.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/my_drop_item.dart';
import 'package:clipshare/app/data/models/pending_file.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/handlers/sync/file_sync_handler.dart';
import 'package:clipshare/app/listeners/dev_alive_listener.dart';
import 'package:clipshare/app/listeners/multi_selection_pop_scope_disable_listener.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/pending_file_service.dart';
import 'package:clipshare/app/services/transport/connection_registry_service.dart';
import 'package:clipshare/app/services/transport/socket_service.dart';
import 'package:clipshare/app/services/syncing_file_progress_service.dart';
import 'package:clipshare/app/utils/file_util.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/sync_file_status.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class _SyncingFilePageTab {
  final String name;
  final Icon icon;

  _SyncingFilePageTab({required this.name, required this.icon});
}

class SyncFileController extends GetxController with GetTickerProviderStateMixin, DevAliveListener implements MultiSelectionPopScopeDisableListener {
  final appConfig = Get.find<ConfigService>();
  final connRegService = Get.find<ConnectionRegistryService>();
  final dbService = Get.find<DbService>();
  final syncingFileService = Get.find<SyncingFileProgressService>();
  final sktService = Get.find<SocketService>();
  final pendingFileService = Get.find<PendingFileService>();

  static const logTag = "SyncingFilePage";
  final tag = "SyncFileController";
  late TabController tabController;
  final emptyContent = EmptyContent(
    description: TranslationKey.dragFileToSend.tr,
  );

  bool selectMode = false;
  final selected = <int, SyncFileStatus>{}.obs;
  final _recHistories = <SyncFileStatus>[].obs;

  ///region tab明细数据
  List<_SyncingFilePageTab> get tabs => [
    _SyncingFilePageTab(
      name: TranslationKey.syncingFilePageHistoryTabText.tr,
      icon: const Icon(
        Icons.history,
        size: 18,
      ),
    ),
    _SyncingFilePageTab(
      name: TranslationKey.syncingFilePageReceiveTabText.tr,
      icon: const Icon(
        Icons.file_download,
        size: 18,
      ),
    ),
    _SyncingFilePageTab(
      name: TranslationKey.syncingFilePageSendTabText.tr,
      icon: const Icon(
        Icons.upload,
        size: 18,
      ),
    ),
  ];

  List<SyncFileStatus> get recHistories => _recHistories;

  List<Column> get sendList {
    final syncingList = syncingFileService.syncingFiles;
    return syncingList
        .where((file) => file.isSender && file.state != SyncingFileState.done)
        .map(
          (e) => Column(
            children: [
              SyncFileStatus(
                syncingFile: e,
                factor: e.savedBytes / e.totalSize,
              ),
              const Divider(
                height: 0,
                indent: 10,
                endIndent: 10,
              ),
            ],
          ),
        )
        .toList();
  }

  List<Column> get recList {
    final syncingList = syncingFileService.syncingFiles;
    return syncingList
        .where((file) => !file.isSender && file.state != SyncingFileState.done)
        .map(
          (e) => Column(
            children: [
              SyncFileStatus(
                syncingFile: e,
                factor: e.savedBytes / e.totalSize,
              ),
              const Divider(
                height: 0,
                indent: 10,
                endIndent: 10,
              ),
            ],
          ),
        )
        .toList();
  }

  ///endregion

  @override
  void onInit() {
    tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    connRegService.addDevAliveListener(this);
    super.onInit();
  }

  @override
  void onReady() {
    final homeController = Get.find<HomeController>();
    homeController.registerMultiSelectionPopScopeDisableListener(this);
    refreshHistoryFiles();
  }

  @override
  void onClose() {
    final homeController = Get.find<HomeController>();
    homeController.removeMultiSelectionPopScopeDisableListener(this);
    connRegService.removeDevAliveListener(this);
    super.onClose();
  }

  @override
  void onDisconnected(String devId) {
    pendingFileService.pendingDevs.removeWhere((dev) => dev.guid == devId);
  }

  Future refreshHistoryFiles() async {
    var files = await dbService.historyDao.getFiles(appConfig.userId);
    var historyList = List<SyncFileStatus>.empty(growable: true);
    for (var history in files) {
      historyList.add(
        SyncFileStatus.fromHistory(
          Get.context!,
          history,
          appConfig.device.guid,
        ),
      );
    }
    _recHistories.value = historyList;
    return Future(() => null);
  }

  Future deleteRecord(bool withFile) {
    Log.debug(tag, "withFile $withFile");
    final context = Get.context!;
    final loadingDialog = Global.showLoadingDialog(
      context: context,
      loadingText: TranslationKey.deleting.tr,
    );
    return dbService.historyDao
        .deleteByIds(
          selected.keys.toList().cast<int>(),
          appConfig.userId,
        )
        .whenComplete(() async {
          bool hasError = false;
          if (withFile) {
            //删除本地文件
            final files = selected.values;
            for (var syncFile in files) {
              final filePath = syncFile.syncingFile.filePath;
              Log.debug(
                tag,
                "will delete file $filePath, isSender ${syncFile.syncingFile.isSender}",
              );
              if (syncFile.syncingFile.isSender) continue;
              try {
                var file = File(filePath);
                if (file.existsSync()) {
                  file.deleteSync();
                }
              } catch (e, stack) {
                Log.error(
                  logTag,
                  "删除文件 $filePath 失败: $e $stack",
                );
                hasError = true;
              }
            }
          }
          refreshHistoryFiles();
          await loadingDialog.close();
          if (hasError) {
            Global.showSnackBarWarn(
              context: context,
              text: TranslationKey.partialDeletionFailed.tr,
            );
          } else {
            Global.showSnackBarSuc(
              context: context,
              text: TranslationKey.deletingSuccess.tr,
            );
          }
        });
  }

  void cancelSelectionMode() {
    selected.clear();
    selectMode = false;
  }

  @override
  void onPopScopeDisableMultiSelection() {
    cancelSelectionMode();
  }
}
