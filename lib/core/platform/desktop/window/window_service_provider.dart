import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/platform/desktop/window/window_service.dart';
import 'package:clipshare/core/settings/hotkey/hotkey_settings_provider.dart';
import 'package:clipshare/core/settings/preference/preference_settings_provider.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/extensions/size_extension.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'window_service_provider.g.dart';

/// 主窗口生命周期服务 keepAlive 单例装配。
///
/// 服务本身无可观察状态，此处仅负责：配置取值器注入（每次读取最新值）、
/// 生命周期挂载（ref.onDispose）、启动时接管系统关闭行为。
@Riverpod(keepAlive: true)
Future<WindowService> windowService(Ref ref) async {
  final service = WindowService(
    rememberWindowSize: () => ref.read(preferenceSettingsProvider).value?.rememberWindowSize ?? false,
    takeOverWinV: () => ref.read(hotkeySettingsProvider).value?.takeOverWinV ?? false,
    restoreWinVOnExit: () => ref.read(hotkeySettingsProvider).value?.restoreWinVOnExit ?? false,
    onWindowSizeChanged: (size) async {
      final db = await ref.read(appDbProvider.future);
      await db.configDao.addOrUpdate(ConfigKey.windowSize, size.str);
      ref.invalidate(preferenceSettingsProvider);
    },
  );
  ref.onDispose(service.dispose);
  if (isDesktop) {
    await service.init();
  }
  return service;
}
