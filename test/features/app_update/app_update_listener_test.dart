import 'dart:async';

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/runtime/app_state/app_state.dart';
import 'package:clipshare/core/runtime/app_state/app_state_provider.dart';
import 'package:clipshare/core/runtime/app_update/app_update_provider.dart';
import 'package:clipshare/core/runtime/app_update/enums/app_update_check_status.dart';
import 'package:clipshare/core/runtime/app_update/models/app_update_check_result.dart';
import 'package:clipshare/core/services/notify/notification_payload.dart';
import 'package:clipshare/core/services/notify/notify_provider.dart';
import 'package:clipshare/core/settings/app_update/app_update_settings.dart';
import 'package:clipshare/core/settings/app_update/app_update_settings_provider.dart';
import 'package:clipshare/features/app_update/widgets/app_update_dialog.dart';
import 'package:clipshare/features/app_update/widgets/app_update_listener.dart';
import 'package:clipshare/l10n/gen/app_localizations_en.dart';
import 'package:clipshare/l10n/l10n_bridge.dart';
import 'package:clipshare/shared/models/update_log.dart';
import 'package:clipshare/shared/models/version.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 隔离设备网络监听，只驱动根层所依赖的启动与鉴权状态。
class _StateNotifier extends AppStateNotifier {
  @override
  AppState build() => const AppState();
}

/// 保留真实广播语义，但不访问网络或注册计时器。
class _Updater extends AppUpdateNotifier {
  final controller = StreamController<AppUpdateCheckResult>.broadcast();
  int starts = 0;

  @override
  void build() {
    ref.onDispose(controller.close);
  }

  @override
  Stream<AppUpdateCheckResult> get events => controller.stream;

  @override
  Future<void> startAutomaticChecks() async {
    starts++;
  }
}

/// 系统通知不是 Widget 测试对象，不调用平台插件。
class _Notify extends NotifyNotifier {
  @override
  Future<void> build() async {}

  @override
  Future<int?> notify({required String content, required String key, String title = appName,
    Uri? notificationLogoUri, NotificationPayload? payload}) async => null;
}

/// 构造真实领域结果供广播和忽略版本校验使用。
AppUpdateCheckResult _available({bool force = false}) => AppUpdateCheckResult(
  status: AppUpdateCheckStatus.available,
  forceCheck: force,
  logs: [UpdateLog(platform: 'all', date: DateTime(2026), version: const AppVersion('9.0.0', '900'),
    desc: 'listener update', downloadUrl: 'https://example.com/app.exe')],
);

void main() {
  setUp(() {
    L10nBridge.bind(AppLocalizationsEn());
  });
  tearDown(() {
    DialogManager.suppressTips = null;
  });

  testWidgets('订阅先于启动注册，锁定时暂存并在解锁后展示', (tester) async {
    final updater = _Updater();
    final appState = _StateNotifier();
    var locked = true;
    DialogManager.suppressTips = () => locked;
    await tester.pumpWidget(ProviderScope(overrides: [
      appUpdateProvider.overrideWith(() => updater),
      appStateProvider.overrideWith(() => appState),
      appUpdateSettingsProvider.overrideWith((ref) async => const AppUpdateSettings()),
      notifyProvider.overrideWith(_Notify.new),
    ], child: MaterialApp(navigatorKey: navigatorKey,
      builder: (_, child) => AppUpdateListener(child: child!), home: const Scaffold())));
    expect(updater.starts, 0);
    appState.updateInitStatus(AppInitStatus.initialized);
    await tester.pump();
    expect(updater.starts, 1);
    updater.controller.add(_available());
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateDialog), findsNothing);
    locked = false;
    appState.updateAuthenticating(true);
    appState.updateAuthenticating(false);
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateDialog), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('暂存期间跳过版本不展示，手动强制结果仍展示', (tester) async {
    final updater = _Updater();
    final appState = _StateNotifier();
    await tester.pumpWidget(ProviderScope(overrides: [
      appUpdateProvider.overrideWith(() => updater),
      appStateProvider.overrideWith(() => appState),
      appUpdateSettingsProvider.overrideWith((ref) async => const AppUpdateSettings(ignoreUpdateVersion: '900')),
      notifyProvider.overrideWith(_Notify.new),
    ], child: MaterialApp(navigatorKey: navigatorKey,
      builder: (_, child) => AppUpdateListener(child: child!), home: const Scaffold())));
    updater.controller.add(_available());
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateDialog), findsNothing);
    updater.controller.add(_available(force: true));
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateDialog), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
