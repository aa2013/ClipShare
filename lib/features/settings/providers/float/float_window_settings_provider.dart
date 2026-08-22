import 'package:clipshare/features/settings/providers/float/float_window_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'float_window_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<FloatWindowSettings> floatWindowSettings(Ref ref) async {
  return const FloatWindowSettings();
}
