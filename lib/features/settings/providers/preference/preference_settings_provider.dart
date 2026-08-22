import 'package:clipshare/features/settings/providers/preference/preference_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'preference_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<PreferenceSettings> preferenceSettings(Ref ref) async {
  return const PreferenceSettings();
}
