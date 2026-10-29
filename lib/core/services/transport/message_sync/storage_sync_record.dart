import 'package:clipshare/core/database/app_database.dart';

/// 存储中转回放的数据没有本地 opRecord.data，需要先替换成可入库的值。
OperationRecord storageSyncRecordFromMap(Map<String, dynamic> map, {String data = ''}) {
  final recordMap = Map<String, dynamic>.from(map);
  recordMap['data'] = data;
  recordMap['storageSync'] = true;
  return OperationRecord.fromJson(recordMap);
}
