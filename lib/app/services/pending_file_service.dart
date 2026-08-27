import 'dart:io';

import 'package:clipshare/app/data/models/my_drop_item.dart';
import 'package:clipshare/app/data/models/pending_file.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/handlers/sync/file_sync_handler.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:clipshare/app/utils/file_util.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:get/get.dart';

class PendingFileService extends GetxService {
  final _pendingItems = <MyDropItem>{};

  final pendingItems = <DropItem>[].obs;
  final pendingDevs = <Device>{}.obs;

  ///添加待发送文件
  void addDropItems(List<DropItem> items) {
    var it = items.map((item) => MyDropItem(item));
    _pendingItems.addAll(it);
    _updatePendingItems();
  }

  ///移除待发送文件
  void removeDropItem(DropItem item) {
    _pendingItems.remove(MyDropItem(item));
    if (_pendingItems.isEmpty) {
      pendingDevs.clear();
    }
    _updatePendingItems();
  }

  void _updatePendingItems() {
    pendingItems.value = _pendingItems.map((item) => item.value).toList(growable: false)
      ..sort((a, b) {
        var typeA = FileSystemEntity.typeSync(a.path);
        var typeB = FileSystemEntity.typeSync(b.path);
        var dir = FileSystemEntityType.directory;
        // 文件夹在前，文件在后
        if (typeA == dir && typeB != dir) {
          return -1;
        } else if (typeA != dir && typeB == dir) {
          return 1;
        } else {
          return 0; // 类型相同，保持原顺序
        }
      });
  }

  ///发送文件
  Future<void> sendPendingFiles() async {
    if (_pendingItems.isEmpty || pendingDevs.isEmpty) {
      return;
    }
    final devices = pendingDevs.toList(growable: false);
    final files = await resolvePendingItems(pendingItems);
    FileSyncHandler.sendFiles(
      devices: devices,
      files: files,
      context: Get.context!,
    );
  }

  ///清除待发送文件信息
  void clearPendingInfo() {
    _pendingItems.clear();
    pendingDevs.clear();
    _updatePendingItems();
  }

  ///解析待发送文件，如果含有文件夹则递归返回，并记录文件夹层级
  Future<List<PendingFile>> resolvePendingItems(List<DropItem> items) async {
    if (items.isEmpty) return [];
    final list = <PendingFile>[];
    for (var item in items) {
      if (item.isUri && item is DropItemFileUri) {
        list.add(
          PendingFile(
            isUri: true,
            isDirectory: false,
            filePath: item.path,
            fileName: item.name,
            size: item.size,
            directories: [],
          ),
        );
        continue;
      }
      final type = await FileSystemEntity.type(item.path);
      if (type == FileSystemEntityType.file) {
        list.add(
          PendingFile(
            isDirectory: false,
            filePath: item.path,
            directories: [],
          ),
        );
        continue;
      }
      final dirPath = item.path;
      final dir = Directory(dirPath);
      final hasDir = await dir.exists();
      if (!hasDir) {
        continue;
      }
      var files = await FileUtil.listFiles(item.path);
      for (var file in files) {
        final parentPath = file.parent.path;
        final dirs = parentPath.replaceFirst(dir.parent.path, "").split(RegExp(r'(/+|\\+)')).where((item) => item.isNotEmpty).toList(growable: false);
        list.add(
          PendingFile(
            isDirectory: true,
            filePath: file.path,
            directories: dirs,
          ),
        );
      }
    }

    return list;
  }
}
