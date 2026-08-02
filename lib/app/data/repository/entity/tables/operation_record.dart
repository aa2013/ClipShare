import 'dart:convert';

import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:get/get.dart';

import '../../db/app_database.dart';

export '../../db/app_database.dart' show OperationRecord;

/// 构造本机操作记录，保持旧同步记录的雪花 id、用户、设备和枚举落库语义。
OperationRecord newOperationRecord(Module module, OpMethod method, Object data) {
  final appConfig = Get.find<ConfigService>();
  return OperationRecord(
    id: appConfig.snowflake.nextId(),
    uid: appConfig.userId,
    devId: appConfig.device.guid,
    module: module,
    moduleEn: module.name,
    method: method,
    data: _operationDataToString(data),
    time: DateTime.now().toString(),
    storageSync: null,
  );
}

/// 从同步/备份 JSON 还原操作记录，兼容 module 使用中文名或枚举名的旧载荷。
OperationRecord operationRecordFromJson(Map<String, dynamic> map) {
  final module = Module.getValue(map['module']);
  return OperationRecord(
    id: map['id'],
    uid: map['uid'],
    devId: map['devId'],
    module: module,
    moduleEn: map['moduleEn'] ?? module.name,
    method: OpMethod.getValue(map['method']),
    data: map['data'],
    time: map['time'],
    storageSync: map['storageSync'],
  );
}

/// 普通标量继续用 toString，复杂对象通过 toJson 序列化，避免 Drift 生成的 toString 进入同步载荷。
String _operationDataToString(Object data) {
  if (data is String || data is num || data is bool) {
    return data.toString();
  }
  return jsonEncode(data);
}
