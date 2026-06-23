import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/extensions/device_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:get/get.dart';

/// 统一发送 socket ackSync，并顺手清理同一远端操作残留的存储 ACK 队列。
class AckSyncSender {
  static const tag = 'AckSyncSender';

  AckSyncSender._();

  static Future<void> send(
    DevInfo senderDev,
    int opId,
    Map<String, dynamic> ackPayload,
  ) async {
    await senderDev.sendData(MsgType.ackSync, ackPayload);
    try {
      await Get.find<DbService>().pendingStorageAckDao.removeByKey(opId, senderDev.guid);
    } catch (err, stack) {
      logger.warn(tag, 'remove pending storage ack failed. opId=$opId, targetDevId=${senderDev.guid}, err=$err, stack=$stack');
    }
  }
}
