import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'discovery_settings.dart';

part 'discovery_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<DiscoverySettings> discoverySettings(Ref ref) async {
  return const DiscoverySettings();
}
