import 'package:clipshare/core/providers/settings/sync/sync_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<SyncSettings> syncSettings(Ref ref) async {
  return const SyncSettings();
}
