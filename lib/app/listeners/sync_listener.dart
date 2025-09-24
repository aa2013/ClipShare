import 'package:clipshare/app/data/models/message_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';

abstract class SyncListener {
  //同步数据
  Future onStorageSync(Map<String, dynamic> map, Device sender, bool loadingMissingData);

  //同步数据
  Future onSync(MessageData msg);

  //确认同步
  Future ackSync(MessageData msg);
}
