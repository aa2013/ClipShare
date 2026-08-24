import 'package:clipshare/core/providers/settings/forward/forward_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'forward_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<ForwardSettings> forwardSettings(Ref ref) async {
  return const ForwardSettings();
}
