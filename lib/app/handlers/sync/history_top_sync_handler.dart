import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/models/message_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_sync.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:get/get.dart';

/// 记录置顶操作同步处理器
class HistoryTopSyncHandler implements SyncListener {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final sktService = Get.find<SocketService>();
  final historyController = Get.find<HistoryController>();

  HistoryTopSyncHandler() {
    sktService.addSyncListener(Module.historyTop, this);
  }

  void dispose() {
    sktService.removeSyncListener(Module.historyTop, this);
  }

  @override
  Future ackSync(MessageData msg) {
    var send = msg.send;
    var data = msg.data;
    var opSync = OperationSync(
      opId: data["id"],
      devId: send.guid,
      uid: appConfig.userId,
    );
    //记录同步记录
    return dbService.opSyncDao.add(opSync);
  }

  @override
  Future onSync(MessageData msg) async {
    var send = msg.send;
    final map = msg.data;
    final historyMap = map["data"] as Map<dynamic, dynamic>;
    map["data"] = "";
    var opRecord = OperationRecord.fromJson(map);
    History history = History.fromJson(historyMap.cast());
    bool success = false;
    switch (opRecord.method) {
      case OpMethod.update:
        success = await dbService.historyDao.setTop(history.id, history.top).then((cnt) => cnt ?? 0) > 0;
        break;
      default:
    }
    if (success) {
      //同步成功后在本地也记录一次
      var originOpRecord = opRecord.copyWith(history.id.toString());
      await dbService.opRecordDao.add(originOpRecord);
    }
    historyController.updateData(
      (his) => his.id == history.id,
      (his) => his.top = history.top,
    );
    //发送同步确认
    sktService.sendData(
      send,
      MsgType.ackSync,
      {"id": opRecord.id, "module": Module.historyTop.moduleName},
    );
  }
}
