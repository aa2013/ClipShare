import 'dart:convert';

import 'package:clipshare/core/database/dao/config_dao.dart';
import 'package:clipshare/core/scheduler/models/task_state.dart';
import 'package:clipshare/shared/enums/config_key.dart';
import 'package:clipshare/shared/utils/log.dart';

/// 调度状态存储
class TaskStateStore {
  static const tag = 'TaskStateStore';

  final ConfigDao configDao;

  /// 内存缓存，null 表示尚未从数据库加载。
  Map<String, TaskState>? _cache;

  TaskStateStore(this.configDao);

  /// 读取指定任务状态，未记录时返回空状态。
  Future<TaskState> read(String key) async {
    final states = await _load();
    return states[key] ?? const TaskState.empty();
  }

  /// 读取全部任务状态快照。
  Future<Map<String, TaskState>> readAll() async {
    return Map<String, TaskState>.unmodifiable(await _load());
  }

  /// 覆盖写入指定任务状态。
  Future<void> write(String key, TaskState state) async {
    final states = Map<String, TaskState>.of(await _load());
    states[key] = state;
    await _persist(states);
  }

  /// 移除指定任务状态，用于任务永久下线时清理残留数据。
  Future<void> remove(String key) async {
    final states = Map<String, TaskState>.of(await _load());
    if (states.remove(key) == null) {
      return;
    }
    await _persist(states);
  }

  /// 加载状态缓存，数据库中无记录或解析失败时返回空表。
  Future<Map<String, TaskState>> _load() async {
    final cached = _cache;
    if (cached != null) {
      return cached;
    }
    final states = <String, TaskState>{};
    try {
      final raw = await configDao.getConfigByKey(ConfigKey.schedulerState, '');
      if (raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            final value = entry.value;
            states[entry.key] = TaskState.tryParse(value is Map<String, dynamic> ? value : null);
          }
        }
      }
    } catch (err, stack) {
      logger.error(tag, 'load scheduler state failed, reset to empty. $err', stack);
    }
    _cache = states;
    return states;
  }

  /// 序列化并写入整份状态快照。
  Future<void> _persist(Map<String, TaskState> states) async {
    _cache = states;
    final json = jsonEncode(states.map((key, value) => MapEntry(key, value.toJson())));
    try {
      await configDao.addOrUpdate(ConfigKey.schedulerState, json);
    } catch (err, stack) {
      logger.error(tag, 'persist scheduler state failed. $err', stack);
    }
  }
}
