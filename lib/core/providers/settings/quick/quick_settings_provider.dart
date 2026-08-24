import 'package:clipshare/core/providers/settings/quick/quick_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<QuickSettings> quickSettings(Ref ref) async {
  //todo query
  return const QuickSettings();
}
