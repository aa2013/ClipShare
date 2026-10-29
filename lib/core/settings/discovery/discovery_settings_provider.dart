import 'package:clipshare/core/constants/network_constants.dart' as net;
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'discovery_settings.dart';

part 'discovery_settings_provider.g.dart';

@Riverpod(keepAlive: true)
Future<DiscoverySettings> discoverySettings(Ref ref) async {
  final cfg = (await ref.read(appDbProvider.future)).configDao;
  return DiscoverySettings(
    port: await cfg.getConfigByKey(.port, net.port),
    allowDiscovery: await cfg.getConfigByKey(.allowDiscover, true),
    onlyForwardMode: await cfg.getConfigByKey(.onlyForwardMode, false),
    heartbeatInterval: await cfg.getConfigByKey(.heartbeatInterval, net.heartbeatInterval),
    autoCloseConnAfterScreenOff: await cfg.getConfigByKey(.autoCloseConnAfterScreenOff, false),
    enableAutoSyncOnScreenOpened: await cfg.getConfigByKey(.enableAutoSyncOnScreenOpened, true),
    keepConnectionsOnNetworkSwitch: await cfg.getConfigByKey(.keepConnectionsOnNetworkSwitch, true),
    onlyManualDiscoverySubNet: await cfg.getConfigByKey(.onlyManualDiscoverySubNet, true),
    noDiscoveryIfs: await cfg.getConfigByKey(
      .noDiscoveryIfs,
      [],
      convert: (content) => content.split(',').where(((item) => item.isNotEmpty)).toList(),
    ),
  );
}
