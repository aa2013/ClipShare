import 'package:clipshare/core/providers/settings/device/device_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<DeviceSettings> deviceSettings(Ref ref) async {
  return const DeviceSettings();
}
