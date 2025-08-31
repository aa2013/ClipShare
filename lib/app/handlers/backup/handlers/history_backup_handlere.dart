import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/models/BackupVersionInfo.dart';
import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/handlers/backup/backup_handler.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:get/get.dart';
import "package:msgpack_dart/msgpack_dart.dart" as m2;

class HistoryBackupHandler with BaseBackupHandler {
  static const tag = "HistoryBackupHandler";
  final dbService = Get.find<DbService>();
  final historyDao = Get.find<DbService>().historyDao;
  final appConfig = Get.find<ConfigService>();

  static const String _name = "history.bin";

  @override
  String get name => _name;

  @override
  Stream<Uint8List> loadData(Directory tempDir) async* {
    var lastId = 0;
    while (true) {
      var list = await historyDao.getHistoriesPage(appConfig.userId, lastId);
      if (list.isEmpty) {
        break;
      }
      for (var item in list) {
        final clip = ClipData(item);
        final json = item.toJson();
        if (clip.isImage) {
          final file = File(item.content);
          if (await file.exists()) {
            //区分截图和普通文件
            final isScreenshot = file.path.contains("Screenshots");
            final relativePath = "files/${isScreenshot ? "Screenshots" : "files"}/${file.fileName}".normalizePath;
            final newFile = File("${tempDir.path}/$relativePath".normalizePath);
            await newFile.create(recursive: true);
            final writer = newFile.openWrite();
            await writer.addStream(file.openRead());
            await writer.close();
            json["content"] = relativePath;
          } else {
            Log.debug(tag, "history ${item.id}: file not found ${file.path}");
          }
        }
        yield m2.serialize(json);
      }
      lastId = list.last.id;
    }
  }

  @override
  Future<int> restore(Uint8List bytes, BackupVersionInfo version, Directory tempDir, RxBool cancel, OnRestoreDone onDone) async {
    final map = m2.deserialize(bytes) as Map<dynamic, dynamic>;
    if (map["type"] == HistoryContentType.image.value) {
      final tempPath = "${tempDir.path}/${map['content']}".normalizePath;
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        final newPath = "${appConfig.fileStorePath}/${tempFile.fileName}".normalizePath;
        final newFile = File(newPath);
        final dir = newFile.parent;
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final writer = newFile.openWrite();
        await writer.addStream(tempFile.openRead());
        await writer.close();
        map["content"] = newPath;
      } else {
        Log.debug(tag, "file not found $tempPath");
      }
    }
    final history = History.fromJson(map.cast<String, dynamic>());
    final rid = appConfig.snowflake.nextId();
    dbService.execSequentially(() {
      if (cancel.value) {
        return Future.value();
      }
      return historyDao.add(history).whenComplete(() => onDone(rid));
    });
    return rid;
  }
}
