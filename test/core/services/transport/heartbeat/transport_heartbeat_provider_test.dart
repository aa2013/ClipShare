import 'package:clipshare/core/platform/channels/android/android_channel_provider.dart';
import 'package:clipshare/core/services/transport/heartbeat/transport_heartbeat_provider.dart';
import 'package:clipshare/core/settings/discovery/discovery_settings.dart';
import 'package:clipshare/core/settings/discovery/discovery_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
// wakelock 平台接口属于传递依赖，测试仅用它替换容器销毁时的平台调用
// ignore: depend_on_referenced_packages
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

/// 隔离 Android 平台通道，心跳服务只订阅其屏幕事件流。
class _FakeAndroidChannelNotifier extends AndroidChannelNotifier {
  @override
  void build() {}
}

/// 吞掉 wakelock 平台调用，避免单测环境缺少插件实现。
class _FakeWakelockPlus extends WakelockPlusPlatformInterface {
  @override
  Future<void> toggle({required bool enable}) async {}
}

void main() {
  late DiscoverySettings settings;
  late ProviderContainer container;
  late TransportHeartbeatNotifier heartbeat;
  late WakelockPlusPlatformInterface originalWakelock;

  setUp(() async {
    originalWakelock = wakelockPlusPlatformInstance;
    wakelockPlusPlatformInstance = _FakeWakelockPlus();
    settings = const DiscoverySettings(heartbeatInterval: 0);
    container = ProviderContainer(
      overrides: [
        androidChannelProvider.overrideWith(_FakeAndroidChannelNotifier.new),
        discoverySettingsProvider.overrideWith((ref) async => settings),
      ],
    );
    await container.read(discoverySettingsProvider.future);
    heartbeat = container.read(transportHeartbeatProvider.notifier);
  });

  tearDown(() {
    container.dispose();
    wakelockPlusPlatformInstance = originalWakelock;
  });

  test('心跳间隔变化后按新间隔重建定时器', () async {
    var tickCount = 0;
    heartbeat.registerTask(
      TransportHeartbeatTask(
        name: 'test',
        shouldRun: () => true,
        onTick: (_) {
          tickCount++;
        },
      ),
    );

    // 间隔为 0 时不应创建定时器
    heartbeat.start('test', immediately: false);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(tickCount, 0);

    // 从关闭切换为 1s 间隔，配置变更后无需重启即可创建定时器
    settings = const DiscoverySettings(heartbeatInterval: 1);
    container.invalidate(discoverySettingsProvider);
    await container.read(discoverySettingsProvider.future);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    expect(tickCount, greaterThanOrEqualTo(1));

    // 关闭心跳后定时器应停止
    settings = const DiscoverySettings(heartbeatInterval: 0);
    container.invalidate(discoverySettingsProvider);
    await container.read(discoverySettingsProvider.future);
    await Future<void>.delayed(Duration.zero);
    final tickBeforeDisable = tickCount;
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    expect(tickCount, tickBeforeDisable);
  });
}
