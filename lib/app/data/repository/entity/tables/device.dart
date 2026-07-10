import 'dart:convert';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:floor/floor.dart';
import 'package:get/get.dart';

@entity
class Device {
  ///设备id
  @primaryKey
  late String guid;

  ///设备名称
  String devName;

  ///用户 id
  int uid;

  ///自定义名称
  String? customName;

  ///设备类型
  String type = "unknown";

  ///链接地址
  String? address;

  ///内网地址
  String? internalAddress;

  ///是否已配对
  bool isPaired;

  String get name => customName == null || customName == "" ? devName : customName!;

  /// UI 展示名：存储/同步仍使用 [name] 的原始值，本机在展示层再按当前语言翻译。
  String get displayName {
    final rawName = name;
    var isSelfDevice = false;
    final appConfig = Get.find<ConfigService>();
    isSelfDevice = guid == appConfig.device.guid;
    if (!isSelfDevice) {
      return rawName;
    }
    final localizedName = TranslationKey.selfDeviceName.tr;
    return localizedName == TranslationKey.selfDeviceName.name ? rawName : localizedName;
  }

  static final unknown = Device.empty(devName: "unknown");

  Device({
    required this.guid,
    required this.devName,
    required this.uid,
    required this.type,
    this.customName,
    this.address,
    this.isPaired = false,
    this.internalAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      "guid": guid,
      "devName": devName,
      "uid": uid,
      "type": type,
      "address": address,
      "customName": customName,
      "isPaired": isPaired,
      "internalAddress": internalAddress,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  Device.empty({
    this.guid = "",
    this.devName = "",
    this.uid = 0,
    this.type = "",
    this.isPaired = false,
  });

  @override
  bool operator ==(Object other) => identical(this, other) || other is Device && runtimeType == other.runtimeType && guid == other.guid && uid == other.uid && type == other.type;

  @override
  int get hashCode => guid.hashCode ^ uid.hashCode ^ type.hashCode;

  static Device fromJson(Map<String, dynamic> map) {
    return Device(
      guid: map["guid"],
      devName: map["devName"],
      uid: map["uid"],
      type: map["type"],
      customName: map["customName"],
      address: map["address"],
      internalAddress: map["internalAddress"],
      isPaired: map["isPaired"],
    );
  }

  static Future<Device?> fromDevInfo(DevInfo dev) {
    final appConfig = Get.find<ConfigService>();
    final dbService = Get.find<DbService>();
    return dbService.deviceDao.getById(dev.guid, appConfig.userId);
  }

  Device copyWith({
    String? guid,
    String? devName,
    int? uid,
    String? type,
    String? customName,
    String? address,
    String? internalAddress,
    bool? isPaired,
  }) {
    return Device(
      guid: guid ?? this.guid,
      devName: devName ?? this.devName,
      uid: uid ?? this.uid,
      type: type ?? this.type,
      customName: customName ?? this.customName,
      address: address ?? this.address,
      internalAddress: internalAddress ?? this.internalAddress,
      isPaired: isPaired ?? this.isPaired,
    );
  }
}
