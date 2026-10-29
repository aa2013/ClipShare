import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'security_settings.dart';

part 'security_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<SecuritySettings> securitySettings(Ref ref) async {
  final cfg = (await ref.read(appDbProvider.future)).configDao;
  return SecuritySettings(
    useAuthentication: await cfg.getConfigByKey(.useAuthentication, false),
    appPassword: await cfg.getConfigByKey(.appPassword, null),
    appRevalidateDuration: await cfg.getConfigByKey(.appRevalidateDuration, 0),
    dhEncryptKey: await cfg.getConfigByKey(.dhEncryptKey, ''),
  );
}
