import 'package:clipshare/core/providers/settings/security/security_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'security_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<SecuritySettings> securitySettings(Ref ref) async {
  return const SecuritySettings();
}
