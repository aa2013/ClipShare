import 'package:clipshare/features/settings/providers/hotkey/hotkey_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'hotkey_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<HotkeySettings> hotkeySettings(Ref ref) async {
  return const HotkeySettings();
}
