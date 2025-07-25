import 'dart:io';

import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/data/models/sync_data_process_result.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/data/repository/entity/tables/history_tag.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:get/get.dart';

class MissingDataSyncHandler {
  static const tag = "SyncDataHandler";

  static void sendMissingData(DevInfo targetDev, String devId, List<String> syncedAppIds) async {
    final appConfig = Get.find<ConfigService>();
    final dbService = Get.find<DbService>();
    final sourceService = Get.find<ClipboardSourceService>();
    final syncRecords = await dbService.opRecordDao.getSyncRecord(appConfig.userId, targetDev.guid, devId);
    final notIncludesAppInfos = sourceService.appInfos
        .where((item) => item.devId == devId && !syncedAppIds.contains(item.appId))
        .map((item) => OperationRecord.fromSimple(Module.appInfo, OpMethod.add, item.id))
        .toList();
    final lst = [...notIncludesAppInfos, ...syncRecords];
    final sktService = Get.find<SocketService>();
    for (var i = 0; i < lst.length; i++) {
      var item = lst[i];
      final seq = i + 1;
      var result = await process(item);
      if (result.shouldRemove) {
        dbService.opRecordDao.deleteByIds([item.id]);
      } else {
        await sktService.sendData(
          targetDev,
          MsgType.missingData,
          {
            "data": result.result,
            "total": lst.length,
            "seq": seq,
          },
        );
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  static Future<SyncDataProcessResult> process(OperationRecord opRecord) async {
    final appConfig = Get.find<ConfigService>();
    final dbService = Get.find<DbService>();
    var shouldRemove = false;
    var id = opRecord.data;
    Map<String, dynamic>? result = opRecord.toJson();
    switch (opRecord.module) {
      case Module.device:
        final device = await dbService.deviceDao.getById(id, appConfig.userId);
        //数据库不存在该数据
        if (device == null) {
          //如果不是delete方法就移除
          if (opRecord.method != OpMethod.delete) {
            shouldRemove = true;
          } else {
            var empty = Device.empty();
            empty.guid = id;
            empty.uid = appConfig.userId;
            result["data"] = empty.toJson();
          }
        } else {
          result["data"] = device.toJson();
        }
        break;
      case Module.tag:
        final historyTag = await dbService.historyTagDao.getById(int.parse(id));
        if (historyTag == null) {
          if (opRecord.method != OpMethod.delete) {
            shouldRemove = true;
          } else {
            var empty = HistoryTag.empty();
            empty.id = int.parse(id);
            result["data"] = empty.toJson();
          }
        } else {
          result["data"] = historyTag.toJson();
        }
        break;
      case Module.history:
        final history = await dbService.historyDao.getById(int.parse(id));
        if (history == null) {
          if (opRecord.method != OpMethod.delete) {
            shouldRemove = true;
          } else {
            var empty = History.empty();
            empty.id = int.parse(id);
            result["data"] = empty.toJson();
          }
        } else {
          var json = history.toJson();
          if (ClipData(history).isImage) {
            var file = File(history.content);
            if (!file.existsSync()) {
              shouldRemove = true;
            } else {
              var fileName = file.fileName;
              var bytes = file.readAsBytesSync();
              json["content"] = {"fileName": fileName, "data": bytes};
            }
          }
          result["data"] = json;
        }
        break;
      case Module.historyTop:
        final history = await dbService.historyDao.getById(int.parse(id));
        if (history == null) {
          if (opRecord.method != OpMethod.delete) {
            shouldRemove = true;
          }
        } else {
          //更新置顶状态，将内容设为空，提高传输效率
          history.content = "";
          result["data"] = history.toJson();
        }
        break;
      case Module.rules:
        //什么都不做
        break;
      case Module.historySource:
        final history = await dbService.historyDao.getById(int.parse(id));
        if (history == null) {
          if (opRecord.method != OpMethod.delete) {
            shouldRemove = true;
          }
        } else {
          //更新来源，将内容设为空，提高传输效率
          history.content = "";
          result["data"] = history.toJson();
        }
        break;
      case Module.appInfo:
        final appInfo = await dbService.appInfoDao.getById(int.parse(id));
        if (appInfo == null) {
          shouldRemove = true;
        } else {
          result["data"] = appInfo.toString();
        }
        break;
      default:
    }
    return SyncDataProcessResult(shouldRemove: shouldRemove, result: result);
  }
}
