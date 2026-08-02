import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:get/get.dart';

import '../../db/app_database.dart';

export '../../db/app_database.dart' show Device;

String _selfGuid = '';

/// 初始化当前 Flutter 引擎的本机设备标识，供展示名本地化使用。
void initializeSelfDeviceGuid(String guid) {
  _selfGuid = guid;
}

/// 构造空设备对象，替代旧实体类的 Device.empty 构造器。
Device emptyDevice({
  String guid = '',
  String devName = '',
  int uid = 0,
  String type = '',
  bool isPaired = false,
  String? customName,
  String? address,
  String? internalAddress,
}) {
  return Device(
    guid: guid,
    devName: devName,
    uid: uid,
    type: type,
    customName: customName,
    address: address,
    internalAddress: internalAddress,
    isPaired: isPaired,
  );
}

/// 未知设备占位对象，避免调用方处理空设备时散落 magic value。
Device unknownDevice() => emptyDevice(devName: 'unknown');

/// 根据发现到的设备信息查询已保存设备，保持旧 Device.fromDevInfo 的语义。
Future<Device?> deviceFromDevInfo(DevInfo dev) {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  return dbService.deviceDao.getById(dev.guid, appConfig.userId);
}

/// 设备行对象的展示和浅拷贝扩展，真实数据类由 Drift 生成。
extension DeviceExt on Device {
  /// 用户可见名称：自定义名称优先，否则使用设备名。
  String get name => customName == null || customName == '' ? devName : customName!;

  /// UI 展示名：本机设备在展示层按当前语言翻译，存储和同步仍使用原始名称。
  String get displayName {
    final rawName = name;
    if (_selfGuid.isEmpty || guid != _selfGuid) {
      return rawName;
    }
    final localizedName = TranslationKey.selfDeviceName.tr;
    return localizedName == TranslationKey.selfDeviceName.name ? rawName : localizedName;
  }
}
