import 'package:clipshare/core/providers/settings/app_update/app_update_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_update_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<AppUpdateSettings> appUpdateSettings(Ref ref) async {
  return const AppUpdateSettings();
}
