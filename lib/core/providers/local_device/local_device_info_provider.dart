import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/providers/settings/device/devicce_id_generate_way.dart';
import 'package:clipshare/core/providers/settings/device/device_settings_provider.dart';
import 'package:clipshare/core/utils/crypto.dart';
import 'package:clipshare/shared/extensions/platform_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/models/local_device_info.dart';
import 'package:clipshare/shared/models/version.dart';
import 'package:device_info_plus/device_info_plus.dart' hide BaseDeviceInfo;
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:persistent_device_id/persistent_device_id.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_device_info_provider.g.dart';

@Riverpod(keepAlive: true)
Future<LocalDeviceInfo> localDeviceInfo(Ref ref) async {
  //读取版本信息
  final pkgInfo = await PackageInfo.fromPlatform();
  final appVersion = AppVersion(pkgInfo.version, pkgInfo.buildNumber);
  var androidOsVersion = 0.0;
  //todo load from db
  final deviceSetting = await ref.watch(deviceSettingsProvider.future);
  var androidDevIdGenerateWay = deviceSetting.androidIdGenerateWay;
  //todo load from db
  var firstStartup = false;
  //todo load from db
  var localName = '';

  //读取设备id信息
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  var guid = '';
  var name = '';
  late final PlatformType type;
  if (isAndroid) {
    var androidInfo = await deviceInfo.androidInfo;
    final useAndroidId = [DeviceIdGenerateWay.unknown, DeviceIdGenerateWay.androidId].contains(androidDevIdGenerateWay);
    if (useAndroidId && !firstStartup) {
      //使用 Android id
      guid = CryptoUtil.toMD5(androidInfo.id);
      //todo update db
      // await setMobileDeviceIdGenerateWay(DeviceIdGenerateWay.androidId);
    } else {
      try {
        //Android id 有可能会重复，如果是首次启动，使用 PersistentDeviceId 生成 id，理论上卸载/重启后都不会变化
        await PersistentDeviceId.getDeviceId().then((id) async {
          if (id != null) {
            guid = CryptoUtil.toMD5(id);
            //todo update db
            // await setMobileDeviceIdGenerateWay(DeviceIdGenerateWay.persistentDeviceId);
          } else {
            //获取失败，仍然使用Android id兜底
            guid = CryptoUtil.toMD5(androidInfo.id);
            //todo update db
            // await setMobileDeviceIdGenerateWay(DeviceIdGenerateWay.androidId);
          }
        });
      } catch (err, stack) {
        guid = CryptoUtil.toMD5(androidInfo.id);
        //todo update db
        // await setMobileDeviceIdGenerateWay(DeviceIdGenerateWay.androidId);
        debugPrint('$err,$stack');
      }
    }
    name = androidInfo.model;
    type = PlatformType.android;
    var release = androidInfo.version.release;
    androidOsVersion = RegExp(r'\d+').firstMatch(release)!.group(0)!.toDouble();
  } else if (isWindows) {
    var windowsInfo = await deviceInfo.windowsInfo;
    guid = CryptoUtil.toMD5(windowsInfo.deviceId);
    name = windowsInfo.computerName;
    type = PlatformType.windows;
  } else if (isLinux) {
    var linuxInfo = await deviceInfo.linuxInfo;
    guid = CryptoUtil.toMD5(linuxInfo.id);
    name = linuxInfo.name;
    type = PlatformType.linux;
  } else if (isMacOS) {
    var macosInfo = await deviceInfo.macOsInfo;
    guid = CryptoUtil.toMD5(macosInfo.systemGUID!);
    name = macosInfo.computerName;
    type = PlatformType.mac;
  } else if (isIOS) {
    var iosInfo = await deviceInfo.iosInfo;
    var id = await PersistentDeviceId.getDeviceId();
    guid = CryptoUtil.toMD5(id!);
    name = iosInfo.name;
    type = PlatformType.ios;
  } else {
    throw Exception('Not Support Platform');
  }

  assert(() {
    guid = 'debug-$guid';
    return true;
  }());

  if (localName.isNullOrEmpty) {
    localName = name;
  } else {
    name = localName;
  }
  final baseDevInfo = BaseDeviceInfo(id: guid, name: name, type: type);
  // final device = Device(
  //   guid: guid,
  //   devName: name,
  //   // todo ConfigService 初始化早于 i18n，不能在这里使用 .tr；展示层再按当前语言本地化。
  //   customName: '本机',
  //   uid: 0,
  //   type: type,
  // );
  return LocalDeviceInfo(
    baseDeviceInfo: baseDevInfo,
    // device: device,
    appVersion: appVersion,
    androidOsVersion: androidOsVersion,
    localName: localName,
  );
}
