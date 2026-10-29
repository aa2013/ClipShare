import 'package:clipshare/shared/utils/log.dart';

/// 设备 id 生成方式
enum DeviceIdGenerateWay {
  androidId,
  persistentDeviceId, //https://pub.dev/packages/persistent_device_id
  unknown;

  static DeviceIdGenerateWay parse(String value) {
    return DeviceIdGenerateWay.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () {
        logger.debug('DeviceIdGenerateWay', "key '$value' unknown");
        return DeviceIdGenerateWay.unknown;
      },
    );
  }
}
