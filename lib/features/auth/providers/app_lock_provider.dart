import 'dart:async';

import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/platform/channels/android/android_channel_provider.dart';
import 'package:clipshare/core/platform/channels/android/events/screen_opened_event.dart';
import 'package:clipshare/core/runtime/app_state/app_state_provider.dart';
import 'package:clipshare/core/settings/quick/quick_settings_provider.dart';
import 'package:clipshare/core/settings/security/security_settings.dart';
import 'package:clipshare/core/settings/security/security_settings_provider.dart';
import 'package:clipshare/features/auth/models/authentication_route_args.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/routing/app_routes.dart';
import 'package:clipshare/shared/utils/dialog.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_lock_provider.g.dart';

/// 应用锁调度器：
/// * 打开验证页（启动锁、超时/亮屏重验、设置页前置验证）
/// * 监听应用生命周期，回到前台超过配置时长时触发重验
/// * 订阅 Android 亮屏事件触发重验
/// * 移动端随安全配置同步防截屏状态
@Riverpod(keepAlive: true)
class AppLockNotifier extends _$AppLockNotifier with WidgetsBindingObserver {
  static const tag = 'AppLockNotifier';

  /// 切后台时间点，用于回到前台时判断是否超时需重验
  DateTime? pausedTime;

  StreamSubscription<ScreenEvent>? _screenEventsSub;
  final _noScreenshot = NoScreenshot.instance;

  //region 内部 getter
  AppStateNotifier get _appState => ref.read(appStateProvider.notifier);

  bool get _authenticating => ref.read(appStateProvider).authenticating;

  SecuritySettings get _securitySettings => ref.read(securitySettingsProvider).requireValue;

  AndroidChannelNotifier get _androidChannel => ref.read(androidChannelProvider.notifier);

  //endregion

  @override
  void build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(_onDispose);
    //验证期间抑制提示弹窗，避免弹窗遮挡验证页
    DialogManager.suppressTips = () => _authenticating;
    //防截屏状态随安全配置变化同步（启动时的初始同步同样经由读取配置完成）
    ref.listen(securitySettingsProvider, (_, next) {
      unawaited(_syncNoScreenshot(next.value));
    });
    unawaited(() async {
      final securitySettings = await ref.read(securitySettingsProvider.future);
      await _syncNoScreenshot(securitySettings);
    }());
    if (isAndroid) {
      _screenEventsSub = _androidChannel.screenEvents.listen(_onScreenEvent);
    }
  }

  void _onDispose() {
    WidgetsBinding.instance.removeObserver(this);
    _screenEventsSub?.cancel();
  }

  /// 打开验证页并等待结果，返回 true 表示验证通过，null 表示取消。
  ///
  /// [lock] 为 true 时不允许直接返回（启动锁与重验场景）。
  Future<bool?> authenticate({bool lock = true, String? localizedReason}) async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      return null;
    }
    _appState.updateAuthenticating(true);
    try {
      final result = await context.pushNamed<bool?>(
        AppRoutes.authentication.name,
        extra: AuthenticationRouteArgs(lock: lock, localizedReason: localizedReason),
      );
      if (result == true) {
        pausedTime = null;
      }
      return result;
    } finally {
      _appState.updateAuthenticating(false);
    }
  }

  /// 启动锁：进入主页后按安全配置触发锁定验证，桌面端最小化启动时跳过
  Future<void> maybeLockOnStartup() async {
    final settings = _securitySettings;
    var startMini = false;
    if (isDesktop) {
      startMini = await ref.read(startMiniProvider.future);
    }
    final shouldLock = shouldLockOnStartup(
      useAuthentication: settings.useAuthentication,
      isDesktop: isDesktop,
      startMini: startMini,
    );
    if (!shouldLock) {
      return;
    }
    await authenticate(
      localizedReason: TranslationKey.authenticationPageTitle.tr,
      lock: true,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _onPausedOrInactive();
        break;
      default:
        break;
    }
  }

  /// 回到前台：已启用安全验证且离开时长达到配置值时触发重验
  void _onResumed() {
    final settings = _securitySettings;
    if (!settings.useAuthentication || _authenticating || pausedTime == null) {
      return;
    }
    final shouldRevalidate = shouldRevalidateOnResume(
      pausedTime: pausedTime,
      revalidateDurationMinutes: settings.appRevalidateDuration,
      now: DateTime.now(),
    );
    if (!shouldRevalidate) {
      return;
    }
    unawaited(_revalidate());
  }

  /// 切后台/失活：记录切后台时间；验证期间切后台则清空，避免误触发重验
  void _onPausedOrInactive() {
    if (pausedTime != null) {
      return;
    }
    if (_authenticating) {
      pausedTime = null;
    } else {
      pausedTime = DateTime.now();
    }
  }

  /// 亮屏事件：验证中或未启用安全验证时跳过
  void _onScreenEvent(ScreenEvent event) {
    if (event is! ScreenOpenedEvent) {
      return;
    }
    final settings = _securitySettings;
    if (_authenticating || !settings.useAuthentication) {
      return;
    }
    unawaited(_revalidate());
  }

  /// 超时/亮屏重验，走锁定模式
  Future<void> _revalidate() {
    return authenticate(
      localizedReason: TranslationKey.authenticationPageBackendTimeoutVerificationTitle.tr,
    );
  }

  /// 移动端开启安全验证时禁止截屏，关闭时恢复
  Future<void> _syncNoScreenshot(SecuritySettings? settings) async {
    if (!(isAndroid || isIOS)) {
      return;
    }
    final useAuthentication = settings?.useAuthentication;
    if (useAuthentication == null) {
      return;
    }
    if (useAuthentication) {
      await _noScreenshot.screenshotOff();
    } else {
      await _noScreenshot.screenshotOn();
    }
  }

  /// 验证成功后由验证页调用，清除切后台时间避免回到前台时重复重验
  void clearPausedTime() {
    pausedTime = null;
  }
}

/// 判断回到前台时是否需要重新验证。
///
/// [pausedTime] 切后台时间点，为空表示无需重验（从未记录或验证期间切后台）；
/// [revalidateDurationMinutes] 配置的重验时长（分钟），0 表示立即重验。
bool shouldRevalidateOnResume({
  required DateTime? pausedTime,
  required int revalidateDurationMinutes,
  required DateTime now,
}) {
  if (pausedTime == null) {
    return false;
  }
  return now.difference(pausedTime).inMinutes >= revalidateDurationMinutes;
}

/// 判断启动时是否需要锁定验证。
///
/// 桌面端最小化启动（托盘静默启动）时跳过锁定。
bool shouldLockOnStartup({
  required bool useAuthentication,
  required bool isDesktop,
  required bool startMini,
}) {
  if (!useAuthentication) {
    return false;
  }
  return !isDesktop || !startMini;
}
