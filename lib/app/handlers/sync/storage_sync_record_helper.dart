import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:drift/drift.dart' show Value;

class StorageSyncRecordHelper {
  const StorageSyncRecordHelper._();

  /// 存储中转回放的数据没有本地 opRecord.data，需要先替换成可入库的值。
  static OperationRecord fromStorageMap(
    Map<String, dynamic> map, {
    String data = '',
  }) {
    final recordMap = Map<String, dynamic>.from(map);
    recordMap['data'] = data;
    recordMap['storageSync'] = true;
    return operationRecordFromJson(recordMap);
  }

  /// 存储中转写回本地操作记录时，必须保留 storageSync=true，避免再次进入补传队列。
  static OperationRecord copyWithStorageData(
    OperationRecord record,
    String data,
  ) {
    return record.copyWith(
      data: data,
      storageSync: const Value(true),
    );
  }
}
