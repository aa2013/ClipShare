import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/shared/utils/snowflake.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'id_provider.g.dart';

@Riverpod(keepAlive: true)
Snowflake id(Ref ref) {
  final localDevInfoProvider = ref.read(localDeviceInfoProvider);
  var localDevId = localDevInfoProvider.requireValue.baseDeviceInfo.id;
  return Snowflake(localDevId.hashCode);
}
