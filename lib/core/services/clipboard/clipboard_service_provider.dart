import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/runtime/app_state/app_state.dart';
import 'package:clipshare/core/runtime/app_state/app_state_provider.dart';
import 'package:clipshare/core/runtime/snowflake/id_provider.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/history/history_event.dart';
import 'package:clipshare/core/services/history/history_recorder_provider.dart';
import 'package:clipshare/core/settings/app_paths/app_paths.dart';
import 'package:clipshare/core/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/core/settings/clipboard/clipboard_settings.dart';
import 'package:clipshare/core/settings/clipboard/clipboard_settings_provider.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';
import 'package:clipshare/shared/utils/file_util.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/snowflake.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:clipshare_clipboard_listener/models/clipboard_source.dart';
import 'package:clipshare_clipboard_listener/models/notification_content_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clipboard_service_provider.g.dart';

/// 插件通知文案配置。
NotificationContentConfig get defaultNotificationContentConfig => NotificationContentConfig(
  errorTitle: TranslationKey.defaultClipboardServerNotificationCfgErrorTitle.tr,
  errorTextPrefix: TranslationKey.defaultClipboardServerNotificationCfgErrorTextPrefix.tr,
  stopListeningTitle: TranslationKey.defaultClipboardServerNotificationCfgStopListeningTitle.tr,
  stopListeningText: TranslationKey.defaultClipboardServerNotificationCfgStopListeningText.tr,
  serviceRunningTitle: TranslationKey.defaultClipboardServerNotificationCfgRunningTitle.tr,
  shizukuRunningText: TranslationKey.defaultClipboardServerNotificationCfgShizukuRunningText.tr,
  rootRunningText: TranslationKey.defaultClipboardServerNotificationCfgRootRunningText.tr,
  shizukuDisconnectedTitle: TranslationKey.defaultClipboardServerNotificationCfgShizukuDisconnectedTitle.tr,
  shizukuDisconnectedText: TranslationKey.defaultClipboardServerNotificationCfgShizukuDisconnectedText.tr,
  waitingRunningTitle: TranslationKey.defaultClipboardServerNotificationCfgWaitingRunningTitle.tr,
  waitingRunningText: TranslationKey.defaultClipboardServerNotificationCfgWaitingRunningText.tr,
);

/// 剪贴板核心服务
@Riverpod(keepAlive: true)
class ClipboardNotifier extends _$ClipboardNotifier with ClipboardListener {
  static const tag = 'ClipboardService';
  bool _initialized = false;
  bool _recoveringShizukuBinderPermission = false;
  bool _requestingShizukuFromBinder = false;
  bool _excludeFormatEnabled = true;

  Snowflake get _idGenerator => ref.read(idProvider);

  LocalDeviceInfo get _localDeviceInfo => ref.read(localDeviceInfoProvider).requireValue;

  ClipboardSettings get _clipboardSettings => ref.read(clipboardSettingsProvider).requireValue;

  AppPaths get _appPaths => ref.read(appPathsProvider).requireValue;

  AppState get _appState => ref.read(appStateProvider);

  @override
  Future<void> build() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    clipboardManager.addListener(this);
    ref.onDispose(_dispose);
    if (isWindows) {
      final execDir = Directory(Platform.resolvedExecutable).parent.path;
      if (!FileUtil.testWriteable(execDir)) {
        await clipboardManager.setTempFileDir(_appPaths.documentsPath);
      }
      await clipboardManager.setExcludeFormatEnabled(_clipboardSettings.isExcludeFormat);
      _excludeFormatEnabled = _clipboardSettings.isExcludeFormat;
      _excludeFormatEnabled = await clipboardManager.isEnableExcludeFormat();
    }
    if (!isAndroid) {
      await clipboardManager.startListening();
    } else {
      await _startListeningOnAndroid(_clipboardSettings.workingMode);
    }
    ref.listen(clipboardSettingsProvider, (previous, next) {
      final settings = next.asData?.value;
      if (settings != null) {
        unawaited(applySettings(settings));
      }
    });
    return;
  }

  /// 应用剪贴板配置变更。
  ///
  /// 当前只处理 Windows 隐私格式排除开关；其他配置在下一次启动监听时读取。
  Future<void> applySettings(ClipboardSettings settings) async {
    if (!isWindows || _excludeFormatEnabled == settings.isExcludeFormat) {
      return;
    }
    await clipboardManager.setExcludeFormatEnabled(settings.isExcludeFormat);
    _excludeFormatEnabled = settings.isExcludeFormat;
  }

  /// 设置 Windows 剪贴板隐私格式排除，并持久化到配置表。
  Future<void> setExcludeFormat(bool enabled) async {
    if (!isWindows) {
      return;
    }
    await clipboardManager.setExcludeFormatEnabled(enabled);
    _excludeFormatEnabled = enabled;
    await _persistExcludeFormat(enabled);
  }

  Future<void> _persistExcludeFormat(bool enabled) async {
    final db = await ref.read(appDbProvider.future);
    await db.configDao.addOrUpdate(ConfigKey.excludeFormat, enabled.toString());
    ref.invalidate(clipboardSettingsProvider);
  }

  @override
  Future<void> onClipboardChanged(
    ClipboardContentType type,
    String content,
    ClipboardSource? source,
  ) async {
    final contentType = HistoryContentType.parse(type.name);
    logger.debug(tag, 'onChange ${content.substring(0, min(content.length, 200))}');
    var size = content.length;
    if (contentType == .image || contentType == .file) {
      final file = File(content);
      if (await file.exists()) {
        size = await file.length();
      } else {
        size = 0;
      }
    }
    final recorder = ref.read(historyRecorderProvider.notifier);
    final event = RawHistoryEvent(
      history: History(
        id: _idGenerator.nextId(),
        uid: 0,
        time: DateTime.now().toString(),
        content: content,
        type: contentType.value,
        devId: _localDeviceInfo.baseDeviceInfo.guid,
        top: false,
        sync: false,
        size: size,
        extracted: null,
      ),
      source: source,
      sync: true,
    );
    recorder.emitRaw(event);
  }

  @override
  void onForegroundChanged(bool isSelf) {
    // 前后台变化属于历史弹窗自动关闭等 UI 行为，本服务只保留监听接口实现。
  }

  @override
  Future<void> onPermissionStatusChanged(
    EnvironmentType environment,
    bool isGranted,
  ) async {
    if (_appState.selectingWorkingMode) {
      return;
    }
    if (environment == EnvironmentType.shizuku && !isGranted) {
      _requestingShizukuFromBinder = false;
      _recoveringShizukuBinderPermission = false;
      logger.warn(tag, 'Shizuku permission is not granted');
      return;
    }
    if (isGranted && environment != EnvironmentType.none && environment != EnvironmentType.androidPre10) {
      await _startListeningOnAndroid(environment);
    }
    if (environment == EnvironmentType.shizuku && isGranted) {
      _requestingShizukuFromBinder = false;
    }
  }

  @override
  Future<void> onShizukuBinderStatusChanged(bool available) async {
    if (!isAndroid) {
      return;
    }
    if (!available) {
      _requestingShizukuFromBinder = false;
      _recoveringShizukuBinderPermission = false;
      logger.warn(tag, 'Shizuku binder disconnected');
      return;
    }
    await _recoverShizukuAfterBinderAvailable();
  }

  /// Shizuku binder 可用后恢复授权和剪贴板监听。
  ///
  /// binder 可用不等于已经授权，因此必须先检查授权状态，再决定是否请求权限。
  Future<void> _recoverShizukuAfterBinderAvailable() async {
    if (_recoveringShizukuBinderPermission || _requestingShizukuFromBinder) {
      return;
    }
    final settings = _clipboardSettings;
    if (settings.workingMode != EnvironmentType.shizuku || _appState.ignoreShizuku || _appState.selectingWorkingMode) {
      return;
    }
    _recoveringShizukuBinderPermission = true;
    try {
      final hasPermission = await clipboardManager.checkPermission(EnvironmentType.shizuku);
      if (hasPermission) {
        await _startListeningOnAndroid(EnvironmentType.shizuku);
        return;
      }
      _requestingShizukuFromBinder = true;
      await clipboardManager.requestPermission(EnvironmentType.shizuku);
    } catch (err, stack) {
      logger.error(tag, err, stack);
      _requestingShizukuFromBinder = false;
    } finally {
      _recoveringShizukuBinderPermission = false;
    }
  }

  /// 使用指定工作环境启动剪贴板监听。
  ///
  /// 通知文案和监听方式均从当前配置读取，确保设置变更后的恢复流程使用最新值。
  Future<void> _startListeningOnAndroid(EnvironmentType environment) async {
    await clipboardManager.startListening(
      env: environment,
      way: _clipboardSettings.listeningWay,
      notificationContentConfig: defaultNotificationContentConfig,
    );
  }

  /// 按当前配置重启 Android 剪贴板监听。
  ///
  /// 工作环境授权变更、监听方式切换等场景都需要在旧监听失效后重新拉起，
  /// 统一走这里以保证通知文案配置与工作模式、监听方式始终来自同一份最新配置。
  Future<void> restartAndroidListening() async {
    if (!isAndroid) {
      return;
    }
    await clipboardManager.stopListening();
    await _startListeningOnAndroid(_clipboardSettings.workingMode);
  }

  /// 释放插件监听和事件流。
  void _dispose() {
    clipboardManager.removeListener(this);
  }
}
