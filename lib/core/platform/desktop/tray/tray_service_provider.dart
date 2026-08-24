import 'dart:async';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/platform/desktop/tray/tray_service.dart';
import 'package:clipshare/core/platform/desktop/window/window_service_provider.dart';
import 'package:clipshare/core/providers/settings/hotkey/hotkey_settings_provider.dart';
import 'package:clipshare/l10n/l10n_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tray_service_provider.g.dart';

/// 托盘服务 keepAlive 单例装配。
@Riverpod(keepAlive: true)
Future<TrayService> trayService(Ref ref) async {
  final service = TrayService(
    showHotKeys: () =>
        ref.read(hotkeySettingsProvider).value?.showMainWindows ?? '',
    exitHotKeys: () =>
        ref.read(hotkeySettingsProvider).value?.exitAppHotKeys ?? '',
    doShowWindow: () async =>
        (await ref.read(windowServiceProvider.future)).showApp(),
    doExitApp: () async =>
        (await ref.read(windowServiceProvider.future)).exitApp(),
  );
  ref.onDispose(service.dispose);
  if (isDesktop) {
    await service.init();
    ref.listen(
      hotkeySettingsProvider,
      (previous, next) => service.updateTrayMenus(),
    );
    ref.listen(uiLocaleProvider, (previous, next) => service.updateTrayMenus());
  }
  return service;
}
