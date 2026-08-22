import 'package:clipshare/features/settings/providers/log/log_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'log_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<LogSettings> logSettings(Ref ref) async {
  return const LogSettings();
}
