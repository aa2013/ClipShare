import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/runtime/app_update/app_update_provider.dart';
import 'package:clipshare/core/runtime/app_update/enums/app_update_check_status.dart';
import 'package:clipshare/core/runtime/app_update/models/app_update_check_result.dart';
import 'package:clipshare/core/scheduler/models/scheduled_task.dart';
import 'package:clipshare/core/scheduler/models/task_result.dart';
import 'package:clipshare/core/scheduler/scheduler.dart';
import 'package:clipshare/core/scheduler/scheduler_provider.dart';
import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/settings/app_update/app_update_settings.dart';
import 'package:clipshare/core/settings/app_update/app_update_settings_provider.dart';
import 'package:clipshare/l10n/l10n_provider.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/models/version.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// 仅提供更新检查实际读取的设备版本。
class _DeviceInfo implements LocalDeviceInfo {
  @override
  AppVersion get appVersion => const AppVersion('1.0', '10');

  /// 未使用的设备字段保持失败，防止测试隐式依赖额外信息。
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 记录注册配置并允许控制注册完成时机。
class _Scheduler implements Scheduler {
  final tasks = <ScheduledTask>[];
  final handles = <TaskHandle>[];
  Completer<void>? registration;

  /// 记录任务，异步屏障用于覆盖注册中释放场景。
  @override
  Future<TaskHandle> register(ScheduledTask task) async {
    tasks.add(task);
    await registration?.future;
    final handle = TaskHandle(() async {});
    handles.add(handle);
    return handle;
  }

  @override
  bool isRegistered(String key) => tasks.any((task) => task.key == key);

  /// 未使用的手动调度不能影响测试。
  @override
  Future<TaskResult> runNow(String key) async => TaskResult.skipped(key, 'unused');

  /// 测试不创建真实定时器。
  @override
  void dispose() {}
}

/// 构造独立依赖容器，避免访问平台插件及真实数据库。
ProviderContainer _container({String? ignored, Locale locale = const Locale('zh'), Scheduler? scheduler}) {
  return ProviderContainer(overrides: [
    localDeviceInfoProvider.overrideWith((ref) async => _DeviceInfo()),
    appUpdateSettingsProvider.overrideWith((ref) async => AppUpdateSettings(ignoreUpdateVersion: ignored)),
    uiLocaleProvider.overrideWithValue(locale),
    if (scheduler != null) schedulerProvider.overrideWith((ref) async => scheduler),
  ]);
}

/// 构造带乱序、其他平台、旧版本的远端响应。
http.Response _response({bool empty = false}) {
  final system = Platform.operatingSystem;
  final key = system[0].toUpperCase() + system.substring(1);
  return http.Response(jsonEncode({
    'downloads': {key: {'url': 'https://example.test/app.exe'}},
    'logs': empty ? [] : [
      for (final entry in [('all', '11'), (system, '13'), ('other', '99'), (system, '10')])
        {'platform': entry.$1, 'date': '2026-01-01', 'version': {'name': '1.1', 'code': entry.$2}, 'desc': '更新'},
    ],
  }), 200, headers: {'content-type': 'application/json; charset=utf-8'});
}

/// 验证运行时状态、串行合并及生命周期语义。
void main() {
  test('filters and sorts logs and chooses localized URLs', () async {
    for (final language in ['zh', 'en']) {
      final container = _container(locale: Locale(language));
      final urls = <Uri>[];
      await http.runWithClient(() async {
        final result = await container.read(appUpdateProvider.notifier).checkUpdate();
        expect(result.status, AppUpdateCheckStatus.available);
        expect(result.logs.map((log) => log.version.code), ['13', '11']);
        expect(result.logs.first.desc, '更新');
      }, () => MockClient((request) async {
        urls.add(request.url);
        return _response();
      }));
      expect(urls.single.path.endsWith(language == 'zh' ? 'version-info.json' : 'version-info.en.json'), isTrue);
      container.dispose();
    }
  });

  test('coalesces equal force flags and serializes different flags', () async {
    final container = _container(ignored: '13');
    final notifier = container.read(appUpdateProvider.notifier);
    final events = <AppUpdateCheckResult>[];
    final subscription = notifier.events.listen(events.add);
    final gate = Completer<void>();
    var requests = 0;
    await http.runWithClient(() async {
      final first = notifier.checkUpdate();
      final same = notifier.checkUpdate();
      final forced = notifier.checkUpdate(forceCheck: true);
      expect(identical(first, same), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(requests, 1);
      gate.complete();
      expect((await first).status, AppUpdateCheckStatus.ignored);
      final forcedResult = await forced;
      expect(forcedResult.status, AppUpdateCheckStatus.available);
      expect(forcedResult.forceCheck, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(events.length, 2);
      expect(requests, 2);
    }, () => MockClient((_) async {
      requests++;
      await gate.future;
      return _response();
    }));
    await subscription.cancel();
    container.dispose();
  });

  test('returns upToDate and preserves request failure details', () async {
    final container = _container();
    final notifier = container.read(appUpdateProvider.notifier);
    await http.runWithClient(() async {
      expect((await notifier.checkUpdate()).status, AppUpdateCheckStatus.upToDate);
    }, () => MockClient((_) async => _response(empty: true)));
    final failure = StateError('network failed');
    await http.runWithClient(() async {
      final result = await notifier.checkUpdate();
      expect(result.status, AppUpdateCheckStatus.failed);
      expect(result.error, same(failure));
      expect(result.stackTrace, isNotNull);
    }, () => MockClient((_) async => throw failure));
    container.dispose();
  });

  test('ignoreVersion persists and invalidates cached settings', () async {
    final database = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    final container = ProviderContainer(overrides: [
      appDbProvider.overrideWith((ref) async => database),
    ]);
    expect((await container.read(appUpdateSettingsProvider.future)).ignoreUpdateVersion, isNull);
    await container.read(appUpdateProvider.notifier).ignoreVersion('13');
    expect(await database.configDao.getConfigByKey(ConfigKey.ignoreUpdateVersion, ''), '13');
    expect((await container.read(appUpdateSettingsProvider.future)).ignoreUpdateVersion, '13');
    container.dispose();
    await database.close();
  });

  test('request timeout returns failed after thirty seconds', () {
    fakeAsync((async) {
      final container = _container();
      AppUpdateCheckResult? result;
      http.runWithClient(() {
        container.read(appUpdateProvider.notifier).checkUpdate().then((value) => result = value);
      }, () => MockClient((_) => Completer<http.Response>().future));
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 29));
      expect(result, isNull);
      async.elapse(const Duration(seconds: 1));
      expect(result?.status, AppUpdateCheckStatus.failed);
      expect(result?.error, isA<TimeoutException>());
      container.dispose();
      async.flushMicrotasks();
    });
  });

  test('automatic registration is idempotent and cancels on dispose', () async {
    final scheduler = _Scheduler();
    final container = _container(scheduler: scheduler);
    final notifier = container.read(appUpdateProvider.notifier);
    await Future.wait([notifier.startAutomaticChecks(), notifier.startAutomaticChecks()]);
    expect(scheduler.tasks.length, 1);
    final task = scheduler.tasks.single;
    expect(task.runImmediately, isTrue);
    final now = DateTime(2026);
    expect(task.schedule.nextRun(now), now.add(const Duration(hours: 2)));
    container.dispose();
    expect(scheduler.handles.single.cancelled, isTrue);
  });

  test('disposal during registration cancels the late handle', () async {
    final scheduler = _Scheduler()..registration = Completer<void>();
    final container = _container(scheduler: scheduler);
    final start = container.read(appUpdateProvider.notifier).startAutomaticChecks();
    await Future<void>.delayed(Duration.zero);
    expect(scheduler.tasks.length, 1);
    container.dispose();
    scheduler.registration!.complete();
    await start;
    expect(scheduler.handles.single.cancelled, isTrue);
  });

  test('disposal suppresses in-flight completion events', () async {
    final container = _container();
    final notifier = container.read(appUpdateProvider.notifier);
    final events = <AppUpdateCheckResult>[];
    final subscription = notifier.events.listen(events.add);
    final gate = Completer<void>();
    await http.runWithClient(() async {
      final pending = notifier.checkUpdate();
      await Future<void>.delayed(Duration.zero);
      container.dispose();
      gate.complete();
      await pending;
      expect(events, isEmpty);
    }, () => MockClient((_) async {
      await gate.future;
      return _response();
    }));
    await subscription.cancel();
  });
}
