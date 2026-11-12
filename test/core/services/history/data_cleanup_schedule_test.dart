import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/scheduler/models/scheduled_task.dart';
import 'package:clipshare/core/scheduler/models/task_result.dart';
import 'package:clipshare/core/scheduler/scheduler.dart';
import 'package:clipshare/core/scheduler/scheduler_provider.dart';
import 'package:clipshare/core/services/device/local_device_info_provider.dart';
import 'package:clipshare/core/services/history/data_cleanup_provider.dart';
import 'package:clipshare/core/settings/data_cleanup/data_cleanup_config.dart';
import 'package:clipshare/core/settings/data_cleanup/data_cleanup_config_provider.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 记录注册请求并按 key 维护当前任务，验证服务侧的注册/注销语义。
class _FakeScheduler implements Scheduler {
  final tasks = <String, ScheduledTask>{};

  /// 每次注销的 key 记录，用于断言关闭自动清理时确实下线任务。
  final cancelled = <String>[];

  @override
  Future<TaskHandle> register(ScheduledTask task) async {
    tasks[task.key] = task;
    return TaskHandle(() async {
      final current = tasks[task.key];
      // 旧句柄不能移除同 key 的新注册，与服务内核保持一致的覆盖语义
      if (!identical(current, task)) {
        return;
      }
      tasks.remove(task.key);
      cancelled.add(task.key);
    });
  }

  @override
  bool isRegistered(String key) => tasks.containsKey(key);

  @override
  Future<TaskResult> runNow(String key) async => TaskResult.skipped(key, 'unused');

  @override
  void dispose() {
    tasks.clear();
  }
}

/// 直接给出配置值，避免测试依赖数据库读取。
class _ConfigNotifier extends DataCleanupConfigNotifier {
  _ConfigNotifier(this.config);

  final DataCleanupConfig? config;

  @override
  Future<DataCleanupConfig?> build() async => config;
}

/// 构造只覆盖配置与调度器的容器，测试不涉及真实清理与数据库。
ProviderContainer _container(_FakeScheduler scheduler, DataCleanupConfig? config) {
  return ProviderContainer(overrides: [
    schedulerProvider.overrideWith((ref) async => scheduler),
    dataCleanupConfigProvider.overrideWith(() => _ConfigNotifier(config)),
  ]);
}

/// 构造启用自动清理的配置，[cron] 用于覆盖合法/非法表达式场景。
DataCleanupConfig _enabledConfig({String? cron = '0 3 * * *'}) {
  return DataCleanupConfig(
    tags: const [],
    devIds: const [],
    contentTypes: const [],
    saveTopData: true,
    removeFiles: false,
    autoClean: true,
    cron: cron,
  );
}

void main() {
  group('DataCleanupNotifier.configureAutoClean', () {
    test('开启自动清理时按配置 cron 注册任务', () async {
      final scheduler = _FakeScheduler();
      final container = _container(scheduler, _enabledConfig());
      await container.read(dataCleanupProvider.future);

      final task = scheduler.tasks[DataCleanupNotifier.schedulerKey];
      expect(task, isNotNull);
      // 启动补跑一次，与关闭前「错过执行时间立即执行」保持一致
      expect(task!.runOnMissed, isTrue);
      expect(task.runImmediately, isFalse);
      // cron 每天 3 点触发，排期必须使用配置中的表达式
      expect(task.schedule.nextRun(DateTime(2026, 1, 1, 8)), DateTime(2026, 1, 2, 3));
      container.dispose();
    });

    test('自动清理关闭时不注册任务', () async {
      final scheduler = _FakeScheduler();
      const config = DataCleanupConfig(
        tags: [],
        devIds: [],
        contentTypes: [],
        saveTopData: true,
        removeFiles: false,
        cron: '0 3 * * *',
      );
      final container = _container(scheduler, config);
      await container.read(dataCleanupProvider.future);

      expect(scheduler.tasks, isEmpty);
      container.dispose();
    });

    test('cron 非法时不注册任务', () async {
      final scheduler = _FakeScheduler();
      final container = _container(scheduler, _enabledConfig(cron: 'not a cron'));
      await container.read(dataCleanupProvider.future);

      expect(scheduler.tasks, isEmpty);
      container.dispose();
    });

    test('重新配置为关闭时注销已注册任务', () async {
      final scheduler = _FakeScheduler();
      final container = _container(scheduler, _enabledConfig());
      await container.read(dataCleanupProvider.future);
      final notifier = container.read(dataCleanupProvider.notifier);
      expect(scheduler.isRegistered(DataCleanupNotifier.schedulerKey), isTrue);

      // 模拟配置改为关闭后重新对齐调度
      container.read(dataCleanupConfigProvider.notifier).state = const AsyncData(
        DataCleanupConfig(
          tags: [],
          devIds: [],
          contentTypes: [],
          saveTopData: true,
          removeFiles: false,
          cron: '0 3 * * *',
        ),
      );
      await notifier.configureAutoClean();

      expect(scheduler.isRegistered(DataCleanupNotifier.schedulerKey), isFalse);
      expect(scheduler.cancelled, contains(DataCleanupNotifier.schedulerKey));
      container.dispose();
    });
  });

  group('DataCleanupNotifier.cleanBySavedConfig 失败边界', () {
    test('孤儿设备回收失败仍回写执行时间', () async {
      final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
      addTearDown(db.close);
      // 使用真实配置 provider，确保回写结果是落库后可读到的值
      await db.configDao.addOrUpdate(ConfigKey.cleanDataConfig, _enabledConfig().toString());
      final container = ProviderContainer(overrides: [
        appDbProvider.overrideWith((ref) async => db),
        // 回收阶段读取设备信息失败：删除已完成，该失败不应阻止回写执行时间
        localDeviceInfoProvider.overrideWith((ref) async => throw StateError('boom')),
      ]);
      // 先等数据库与配置就绪，生产环境由启动预加载保证该顺序
      await container.read(appDbProvider.future);
      final before = await container.read(dataCleanupConfigProvider.future);
      expect(before?.lastCleanTime, isNull);
      final notifier = container.read(dataCleanupProvider.notifier);

      await notifier.cleanBySavedConfig();

      final after = await container.read(dataCleanupConfigProvider.future);
      expect(after?.lastCleanTime, isNotNull);
      expect(after?.nextCleanTime, isNotNull);
      container.dispose();
    });
  });
}
