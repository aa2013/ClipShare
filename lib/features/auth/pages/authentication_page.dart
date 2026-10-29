import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/platform/channels/android/android_channel_provider.dart';
import 'package:clipshare/core/runtime/app_state/app_state.dart';
import 'package:clipshare/core/runtime/app_state/app_state_provider.dart';
import 'package:clipshare/core/settings/security/security_settings_provider.dart';
import 'package:clipshare/features/auth/models/authentication_route_args.dart';
import 'package:clipshare/features/auth/providers/app_lock_provider.dart';
import 'package:clipshare/features/auth/widgets/auth_password_input.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/utils/crypto.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

/// 验证页：应用锁密码验证与系统生物识别验证。
///
/// [args.lock] 为 true 时为锁定模式，禁止直接返回，验证成功前停留在本页。
class AuthenticationPage extends ConsumerStatefulWidget {
  final AuthenticationRouteArgs args;

  const AuthenticationPage({super.key, required this.args});

  @override
  ConsumerState<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends ConsumerState<AuthenticationPage> {
  static const tag = 'AuthenticationPage';
  final _auth = LocalAuthentication();

  /// 设备是否支持生物识别
  var _supportAuth = false;

  /// 系统验证进行中标志，避免重复拉起系统验证
  var _authenticating = false;

  /// 是否允许返回（锁定模式禁止返回，验证成功后置为 true）
  var _backPage = false;

  String? _localizedReason;

  AppStateNotifier get _appStateNotifier => ref.read(appStateProvider.notifier);

  AppState get _appState => ref.read(appStateProvider);

  @override
  void initState() {
    super.initState();
    final args = widget.args;
    _backPage = !args.lock;
    _localizedReason = args.localizedReason;
    _auth.isDeviceSupported().then((supported) {
      _supportAuth = supported;
      if (!_supportAuth || !mounted) {
        return;
      }
      showBottomSheetAuthentication();
    });
  }

  /// 兜底复位全局验证状态，防止异常退出验证页后状态残留
  @override
  void dispose() {
    _appStateNotifier.updateAuthenticating(false);
    super.dispose();
  }

  /// 验证成功统一收口：复位验证状态、清除切后台时间并携带结果退出
  ///
  /// [useSystem] 为 true 表示系统生物识别验证成功，此时底部弹窗仍开启，需再退一级。
  void onAuthenticated([bool useSystem = false]) {
    final appLock = ref.read(appLockProvider.notifier);
    _appStateNotifier.updateAuthenticating(false);
    appLock.clearPausedTime();
    setState(() {
      _backPage = true;
    });
    context.pop(true);
    if (useSystem) {
      context.pop(true);
    }
  }

  /// 拉起系统生物识别验证，成功后按系统验证流程收口
  Future<void> authenticate() async {
    final authenticated = await checkAuth();
    if (authenticated) {
      onAuthenticated(true);
    }
  }

  /// 调用系统生物识别验证，验证进行中时不重复拉起
  Future<bool> checkAuth() async {
    if (_supportAuth && !_authenticating) {
      _authenticating = true;
      final authenticated = await _auth.authenticate(
        authMessages: [
          AndroidAuthMessages(
            biometricHint: '',
            signInTitle: TranslationKey.authenticationPageRequireAuthentication.tr,
          ),
        ],
        localizedReason: _localizedReason ?? TranslationKey.authenticationPageTitle.tr,
      );
      _authenticating = false;
      logger.debug(tag, 'authenticated $authenticated');
      return authenticated;
    }
    return false;
  }

  /// 底部生物识别验证面板：可直接开始系统验证或改用密码验证
  void showBottomSheetAuthentication() {
    showModalBottomSheet(
      clipBehavior: Clip.antiAlias,
      context: context,
      showDragHandle: true,
      isDismissible: false,
      elevation: 100,
      builder: (sheetContext) {
        authenticate();
        return SafeArea(
          child: Container(
            constraints: const BoxConstraints(minWidth: 500),
            padding: const EdgeInsets.only(bottom: 30, top: 10),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    TranslationKey.authenticationPageTitle.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: TextButton(
                      child: Text(
                        TranslationKey.authenticationPageUsePassword.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      onPressed: () {
                        Future.delayed(100.ms, () {
                          if (!sheetContext.mounted) {
                            return;
                          }
                          Navigator.pop(sheetContext);
                        });
                      },
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: authenticate,
                        child: const Icon(
                          Icons.fingerprint_outlined,
                          color: Colors.blueAccent,
                          size: 100,
                        ),
                      ),
                      TextButton(
                        onPressed: authenticate,
                        child: Text(TranslationKey.authenticationPageStartVerification.tr),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final securitySettings = ref.watch(securitySettingsProvider).requireValue;
    final appPassword = securitySettings.appPassword;
    return PopScope(
      canPop: _backPage,
      onPopInvokedWithResult: _backPage
          ? null
          : (bool didPop, Object? result) {
              if (isAndroid && _appState.authenticating) {
                final androidChannel = ref.read(androidChannelProvider.notifier);
                androidChannel.moveToBg();
              }
            },
      child: Scaffold(
        body: AuthPasswordInput(
          onFinished: (String input, String? second) {
            return CryptoUtil.toMD5(input) == appPassword;
          },
          onOk: (input) {
            onAuthenticated();
            return false;
          },
          showCancelBtn: _backPage,
        ),
      ),
    );
  }
}
