import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/providers/settings/device/device_settings.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'device_paried_filter_status.dart';

part 'device_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<DeviceSettings> deviceSettings(Ref ref) async {
  final db = await ref.watch(appDbProvider.future);
  final pairedStatusFilter = await db.configDao.getConfigByKey(
    ConfigKey.devicePairedStatusFilter,
    DevicePairedStatusFilter.all,
    convert: DevicePairedStatusFilter.parse,
  );
  final dhKey = await db.configDao.getConfigByKey(ConfigKey.dhEncryptKey, null);
  final customName = await db.configDao.getConfigByKey(ConfigKey.localName, null);
  return DeviceSettings(
    pairedStatusFilter: pairedStatusFilter,
    dhAesKey: dhKey,
    customName: customName,
  );
}
