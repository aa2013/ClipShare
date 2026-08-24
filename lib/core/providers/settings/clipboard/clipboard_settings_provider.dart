import 'package:clipshare/core/providers/settings/clipboard/clipboard_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clipboard_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<ClipboardSettings> clipboardSettings(Ref ref) async {
  return const ClipboardSettings();
}
