import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare/core/providers/app_state/app_state.dart';
import 'package:clipshare/core/providers/settings/app_paths/app_paths.dart';
import 'package:clipshare/core/providers/settings/clipboard/clipboard_settings.dart';
import 'package:clipshare/core/utils/file_util.dart';
import 'package:clipshare/core/utils/snowflake.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';
import 'package:clipshare/shared/models/local_device_info.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:clipshare_clipboard_listener/models/clipboard_source.dart';
import 'package:clipshare_clipboard_listener/models/notification_content_config.dart';

import '../history/history_event.dart';

/// 剪贴板核心运行时服务。
class ClipboardService with ClipboardListener {
  static const tag = 'ClipboardService';

  final Future<ClipboardSettings> Function() _loadSettings;
  final Future<AppPaths> Function() _loadAppPaths;
  final AppState Function() _readAppState;
  final Future<void> Function(bool enabled) _persistExcludeFormat;
  final void Function(ClipboardHistoryEvent event) _onChanged;
  final Snowflake _idGenerator;
  final LocalDeviceInfo _localDeviceInfo;

  bool _initialized = false;
  bool _recoveringShizukuBinderPermission = false;
  bool _requestingShizukuFromBinder = false;
  bool _excludeFormatEnabled = true;

  ClipboardService({
    required Future<ClipboardSettings> Function() loadSettings,
    required Future<AppPaths> Function() loadAppPaths,
    required AppState Function() readAppState,
    required Future<void> Function(bool enabled) persistExcludeFormat,
    required void Function(ClipboardHistoryEvent event) onChanged,
    required Snowflake idGenerator,
    required LocalDeviceInfo localDeviceInfo,
  })  : _loadSettings = loadSettings,
        _loadAppPaths = loadAppPaths,
        _readAppState = readAppState,
        _idGenerator = idGenerator,
        _localDeviceInfo = localDeviceInfo,
        _onChanged = onChanged,
        _persistExcludeFormat = persistExcludeFormat;

  /// 插件通知文案配置。
  static NotificationContentConfig get defaultNotificationContentConfig =>
      NotificationContentConfig(
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

  /// 初始化剪贴板插件监听，并同步平台相关的剪贴板设置。
  Future<ClipboardService> init() async {
    if (_initialized) {
      return this;
    }
    _initialized = true;
    clipboardManager.addListener(this);
    final appPaths = await _loadAppPaths();
    final settings = await _loadSettings();
    if (Platform.isWindows) {
      final execDir = Directory(Platform.resolvedExecutable).parent.path;
      if (!FileUtil.testWriteable(execDir)) {
        await clipboardManager.setTempFileDir(appPaths.documentsPath);
      }
      await clipboardManager.setExcludeFormatEnabled(settings.isExcludeFormat);
      _excludeFormatEnabled = settings.isExcludeFormat;
      _excludeFormatEnabled = await clipboardManager.isEnableExcludeFormat();
    }
    return this;
  }

  /// 应用剪贴板配置变更。
  ///
  /// 当前只处理 Windows 隐私格式排除开关；其他配置在下一次启动监听时读取。
  Future<void> applySettings(ClipboardSettings settings) async {
    if (!Platform.isWindows || _excludeFormatEnabled == settings.isExcludeFormat) {
      return;
    }
    await clipboardManager.setExcludeFormatEnabled(settings.isExcludeFormat);
    _excludeFormatEnabled = settings.isExcludeFormat;
  }

  /// 设置 Windows 剪贴板隐私格式排除，并持久化到配置表。
  Future<void> setExcludeFormat(bool enabled) async {
    if (!Platform.isWindows) {
      return;
    }
    await clipboardManager.setExcludeFormatEnabled(enabled);
    _excludeFormatEnabled = enabled;
    await _persistExcludeFormat(enabled);
  }

  @override
  void onClipboardChanged(
    ClipboardContentType type,
    String content,
    ClipboardSource? source,
  ) {
    final contentType = HistoryContentType.parse(type.name);
    logger.debug(tag, 'onChange ${content.substring(0, min(content.length, 200))}');
    _onChanged(
      ClipboardHistoryEvent(
        history: History(
          id: _idGenerator.nextId(),
          uid: 0,
          time: DateTime.now().toString(),
          content: content,
          type: contentType.value,
          devId: _localDeviceInfo.baseDeviceInfo.id,
          top: false,
          sync: false,
          size: content.length,
        ),
        source: source,
      ),
    );
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
    if (_readAppState().selectingWorkingMode) {
      return;
    }
    if (environment == EnvironmentType.shizuku && !isGranted) {
      _requestingShizukuFromBinder = false;
      _recoveringShizukuBinderPermission = false;
      logger.warn(tag, 'Shizuku permission is not granted');
      return;
    }
    if (isGranted &&
        environment != EnvironmentType.none &&
        environment != EnvironmentType.androidPre10) {
      await _startListeningWithEnvironment(environment);
    }
    if (environment == EnvironmentType.shizuku && isGranted) {
      _requestingShizukuFromBinder = false;
    }
  }

  @override
  Future<void> onShizukuBinderStatusChanged(bool available) async {
    if (!Platform.isAndroid) {
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
    final appState = _readAppState();
    final settings = await _loadSettings();
    if (settings.workingMode != EnvironmentType.shizuku ||
        appState.ignoreShizuku ||
        appState.selectingWorkingMode) {
      return;
    }
    _recoveringShizukuBinderPermission = true;
    try {
      final hasPermission = await clipboardManager.checkPermission(EnvironmentType.shizuku);
      if (hasPermission) {
        await _startListeningWithEnvironment(EnvironmentType.shizuku);
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
  Future<void> _startListeningWithEnvironment(EnvironmentType environment) async {
    final settings = await _loadSettings();
    await clipboardManager.startListening(
      env: environment,
      way: settings.listeningWay,
      notificationContentConfig: ClipboardService.defaultNotificationContentConfig,
    );
  }

  /// 释放插件监听和事件流。
  void dispose() {
    clipboardManager.removeListener(this);
  }
}
