import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/constants/url_constants.dart';
import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/runtime/app_update/enums/app_update_check_status.dart';
import 'package:clipshare/core/runtime/app_update/models/app_update_check_result.dart';
import 'package:clipshare/core/runtime/app_update/utils/app_update_task_handler.dart';
import 'package:clipshare/core/scheduler/models/scheduled_task.dart';
import 'package:clipshare/core/scheduler/schedule/interval_schedule.dart';
import 'package:clipshare/core/scheduler/scheduler.dart';
import 'package:clipshare/core/scheduler/scheduler_provider.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/settings/app_update/app_update_settings.dart';
import 'package:clipshare/core/settings/app_update/app_update_settings_provider.dart';
import 'package:clipshare/l10n/app_language.dart';
import 'package:clipshare/l10n/l10n_provider.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/exceptions/fetch_update_logs_exception.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/models/update_log.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_update_provider.g.dart';

/// 无界面的更新运行时，统一调度、并发检查与结果广播。
@Riverpod(keepAlive: true)
class AppUpdateNotifier extends _$AppUpdateNotifier {
  static const automaticTaskKey = 'app_update';
  static const automaticInterval = Duration(hours: 2);
  static const requestTimeout = Duration(seconds: 30);
  static const _defaultInfoFile = 'version-info.json';
  static const _englishInfoFile = 'version-info.en.json';

  final _events = StreamController<AppUpdateCheckResult>.broadcast();
  final _pending = <bool, Future<AppUpdateCheckResult>>{};
  Future<void> _tail = Future.value();
  Future<void>? _automaticStart;
  TaskHandle? _taskHandle;
  http.Client? _activeClient;
  bool _disposed = false;

  Future<LocalDeviceInfo> get _deviceInfo => ref.read(localDeviceInfoProvider.future);
  Future<AppUpdateSettings> get _settings => ref.read(appUpdateSettingsProvider.future);
  Future<AppDatabase> get _database => ref.read(appDbProvider.future);
  Future<Scheduler> get _scheduler => ref.read(schedulerProvider.future);
  Locale get _locale => ref.read(uiLocaleProvider);

  Stream<AppUpdateCheckResult> get events => _events.stream;

  @override
  void build() {
    ref.onDispose(_dispose);
  }

  Future<AppUpdateCheckResult> checkUpdate({bool forceCheck = false}) {
    final existing = _pending[forceCheck];
    if (existing != null) {
      return existing;
    }
    final completer = Completer<AppUpdateCheckResult>();
    _pending[forceCheck] = completer.future;
    _tail = _tail.then((_) async {
      final result = await _check(forceCheck);
      // 移除的是本次仍待完成的 Future，不能在完成 completer 前等待它。
      final removed = _pending.remove(forceCheck);
      assert(identical(removed, completer.future));
      if (!_disposed) {
        _events.add(result);
      }
      completer.complete(result);
    });
    return completer.future;
  }

  /// 拉取并过滤当前平台的新版本
  Future<AppUpdateCheckResult> _check(bool forceCheck) async {
    try {
      if (_disposed) {
        throw StateError('app update runtime is disposed');
      }
      final deviceFuture = _deviceInfo;
      final settingsFuture = _settings;
      final locale = _locale;
      // 同时监听依赖失败，防止其中一个先失败时出现无人接收的异步错误。
      final dependencies = await Future.wait<Object>([deviceFuture, settingsFuture]);
      final version = (dependencies[0] as LocalDeviceInfo).appVersion;
      final settings = dependencies[1] as AppUpdateSettings;
      if (_disposed) {
        throw StateError('app update runtime is disposed');
      }
      final url = locale.languageCode.toLowerCase() == AppLanguage.zhCnLocale.languageCode
          ? appUpdateInfoUrl
          : appUpdateInfoUrl.replaceFirst(_defaultInfoFile, _englishInfoFile);
      final client = http.Client();
      _activeClient = client;
      late final http.Response response;
      try {
        response = await client.get(Uri.parse(url)).timeout(requestTimeout);
      } finally {
        client.close();
        _activeClient = null;
      }
      if (response.statusCode != 200) {
        throw FetchUpdateLogsException(response.statusCode.toString());
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final system = isMacOS ? 'MacOS' : isIOS ? 'IOS' : Platform.operatingSystem;
      final logs = <UpdateLog>[];
      for (final raw in body['logs'] as List<dynamic>) {
        final json = Map<String, dynamic>.from(raw as Map);
        json['url'] = body['downloads'][system.upperFirst]['url'];
        final log = UpdateLog.fromJson(json);
        final platform = log.platform.toLowerCase();
        if ((platform != system.toLowerCase() && platform != 'all') || log.version <= version) {
          continue;
        }
        logs.add(log);
      }
      logs.sort((a, b) => b.version - a.version);
      final status = logs.isEmpty
          ? AppUpdateCheckStatus.upToDate
          : !forceCheck && logs.first.version.code == settings.ignoreUpdateVersion
              ? AppUpdateCheckStatus.ignored
              : AppUpdateCheckStatus.available;
      return AppUpdateCheckResult(status: status, logs: logs, forceCheck: forceCheck);
    } catch (error, stackTrace) {
      return AppUpdateCheckResult(
        status: AppUpdateCheckStatus.failed,
        error: error,
        stackTrace: stackTrace,
        forceCheck: forceCheck,
      );
    }
  }

  /// 忽略版本
  Future<void> ignoreVersion(String versionCode) async {
    final database = await _database;
    await database.configDao.addOrUpdate(.ignoreUpdateVersion, versionCode);
    if (!_disposed) {
      ref.invalidate(appUpdateSettingsProvider);
    }
  }

  /// 幂等注册立即执行及两小时周期检查，注册失败时允许再次启动。
  Future<void> startAutomaticChecks() {
    return _automaticStart ??= _startAutomaticChecks();
  }

  /// 在异步注册前后检查生命周期
  Future<void> _startAutomaticChecks() async {
    try {
      if (_disposed) {
        return;
      }
      final scheduler = await _scheduler;
      if (_disposed) {
        return;
      }
      //注册任务
      final handle = await scheduler.register(ScheduledTask(
        key: automaticTaskKey,
        schedule: const IntervalSchedule(automaticInterval),
        handler: AppUpdateTaskHandler(() => checkUpdate()),
        runImmediately: true,
        runOnMissed: false,
      ));
      if (_disposed) {
        await handle.cancel();
      } else {
        _taskHandle = handle;
      }
    } catch (_) {
      _automaticStart = null;
      rethrow;
    }
  }

  void _dispose() {
    _disposed = true;
    _activeClient?.close();
    _activeClient = null;
    unawaited(_events.close());
    final handle = _taskHandle;
    if (handle != null) {
      unawaited(handle.cancel());
    }
  }
}
