import 'dart:io';

import 'package:clipshare/app/data/enums/syncing_file_state.dart';
import 'package:clipshare/app/data/models/syncing_file.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/modules/sync_file_module/sync_file_controller.dart';
import 'package:get/get.dart';

class SyncingFileProgressService extends GetxService {
  final _syncingFilesMap = <String, SyncingFile>{}.obs;

  Future<SyncingFileProgressService> init() async {
    return this;
  }

  void updateSyncingFile(SyncingFile syncingFile) {
    _syncingFilesMap[syncingFile.filePath] = syncingFile;
    _postHandle(syncingFile);
  }

  void removeSyncingFile(String filePath) {
    if (!_syncingFilesMap.containsKey(filePath)) return;
    var syncingFile = _syncingFilesMap[filePath];
    _syncingFilesMap.remove(filePath);
    _postHandle(syncingFile!);
  }

  void clearAll() {
    _syncingFilesMap.clear();
  }

  void _postHandle(SyncingFile syncingFile) {
    var isSender = syncingFile.isSender;
    switch (syncingFile.state) {
      case SyncingFileState.error:
        if (isSender) break;
        File(syncingFile.filePath).delete();
        break;
      case SyncingFileState.done:
        final controller = Get.find<SyncFileController>();
        controller.refreshHistoryFiles();
        break;
      default:
    }
  }

  List<SyncingFile> get syncingFiles {
    final list = _syncingFilesMap.values.toList();
    list.sort((a, b) {
      if (a.state == b.state) {
        return a.fromDev.name.compareTo(b.fromDev.name);
      }
      return a.state.order.compareTo(b.state.order);
    });
    return list;
  }
}
