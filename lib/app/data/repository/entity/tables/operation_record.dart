import 'dart:convert';

import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:floor/floor.dart';
import 'package:get/get.dart';

///
/// 操作记录表
@Entity(
  indices: [
    Index(value: ['uid', "module", "method"]),
  ],
)
class OperationRecord {
  ///主键 id
  @primaryKey
  late int id;

  ///用户 id
  late int uid;

  ///记录来自哪台设备
  late String devId;

  ///操作模块
  @TypeConverters([ModuleTypeConverter])
  late Module module;

  /// 操作方法
  @TypeConverters([OpMethodTypeConverter])
  late OpMethod method;

  /// history的主键
  late String data;

  /// 操作时间
  String time = DateTime.now().toString();

  /// 存储服务同步
  /// true 为已向存储服务同步
  /// false 为未同步（如网络问题同步失败）
  /// null 为以前还未启用存储服务时的数据
  bool? storageSync;

  OperationRecord({
    required this.id,
    required this.uid,
    required this.devId,
    required this.module,
    required this.method,
    required this.data,
    this.storageSync,
  });

  OperationRecord.fromSimple(this.module, this.method, Object data) {
    final appConfig = Get.find<ConfigService>();
    id = appConfig.snowflake.nextId();
    uid = appConfig.userId;
    devId = appConfig.device.guid;
    this.data = data.toString();
  }

  static OperationRecord fromJson(map) {
    var id = map["id"];
    var uid = map["uid"];
    var module = Module.getValue((map["module"]));
    var method = OpMethod.getValue(map["method"]);
    var data = map["data"];
    var time = map["time"];
    var devId = map["devId"];
    var storageSync = map["storageSync"];
    var record = OperationRecord(
      id: id,
      uid: uid,
      devId: devId,
      module: module,
      method: method,
      data: data,
      storageSync: storageSync,
    );
    record.time = time;
    return record;
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "uid": uid,
      "devId": devId,
      "module": module.moduleName,
      "method": method.name,
      "data": data,
      "time": time,
      "storageSync": storageSync,
    };
  }

  OperationRecord copyWith({
    int? id,
    int? uid,
    String? devId,
    Module? module,
    OpMethod? method,
    String? data,
    bool? storageSync,
  }) {
    return OperationRecord(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      devId: devId ?? this.devId,
      module: module ?? this.module,
      method: method ?? this.method,
      data: data ?? this.data,
      storageSync: storageSync ?? this.storageSync,
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

// 枚举类型到String的转换器
class OpMethodTypeConverter extends TypeConverter<OpMethod, String> {
  @override
  OpMethod decode(String name) {
    return OpMethod.getValue(name);
  }

  @override
  String encode(OpMethod value) {
    return value.name;
  }
}

// 枚举类型到String的转换器
class ModuleTypeConverter extends TypeConverter<Module, String> {
  @override
  Module decode(String name) {
    return Module.getValue(name);
  }

  @override
  String encode(Module value) {
    return value.moduleName;
  }
}
