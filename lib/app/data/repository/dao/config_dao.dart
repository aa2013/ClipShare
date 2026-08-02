import 'package:clipshare/app/data/enums/config_key.dart';
import 'package:clipshare/app/data/repository/db/app_database.dart';
import 'package:clipshare/app/data/repository/db/app_tables.dart';
import 'package:clipshare/app/data/repository/entity/tables/config.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:drift/drift.dart';

part 'config_dao.g.dart';

@DriftAccessor(tables: [Configs])
class ConfigDao extends DatabaseAccessor<AppDatabase> with _$ConfigDaoMixin {
  ConfigDao(super.attachedDatabase);

  static const tag = "ConfigDao";

  /// 获取指定用户的全部配置项。
  Future<List<Config>> getAllConfigs(int uid) {
    return (select(configs)..where((tbl) => tbl.uid.equals(uid))).get();
  }

  /// 获取指定配置值，旧配置表以 key 为主键并保留 uid 过滤。
  Future<String?> getConfig(String key, int uid) async {
    final row = await (select(configs)..where((tbl) => tbl.key.equals(key) & tbl.uid.equals(uid))).getSingleOrNull();
    return row?.value;
  }

  /// 按配置枚举读取并转换类型，保持旧服务层默认值语义。
  Future<T> getConfigByKey<T>(ConfigKey key, T defValue, {T Function(String value)? convert}) async {
    final value = await getConfig(key.name, 0);
    if (value == null) {
      return defValue;
    }
    if (defValue is String || (defValue == null && convert == null)) {
      return value as T;
    }
    if (defValue is int) {
      return value.toInt() as T;
    }
    if (defValue is double) {
      return value.toDouble() as T;
    }
    if (defValue is bool) {
      return value.toBool() as T;
    }
    if (convert == null && defValue == null) {
      return defValue;
    }
    if (convert == null) {
      throw 'No matching conversion method available';
    }
    return convert.call(value);
  }

  /// 插入配置，主键冲突由调用方决定是否改用 [addOrUpdate]。
  Future<int> add(Config config) {
    return into(configs).insert(
      ConfigsCompanion.insert(
        key: config.key,
        value: config.value,
        uid: config.uid,
      ),
    );
  }

  /// 全量更新配置值，按旧表主键 key 定位。
  Future<int> updateConfig(Config config) {
    return (update(configs)..where((tbl) => tbl.key.equals(config.key))).write(
      ConfigsCompanion(
        value: Value(config.value),
        uid: Value(config.uid),
      ),
    );
  }

  /// 删除完整配置对象，兼容旧 DAO 调用习惯。
  Future<int> remove(Config config) {
    return (delete(configs)..where((tbl) => tbl.key.equals(config.key))).go();
  }

  /// 根据 key 和 uid 删除配置，避免误删未来可能恢复的多用户配置。
  Future<void> removeByKey(String key, int uid) async {
    await (delete(configs)..where((tbl) => tbl.key.equals(key) & tbl.uid.equals(uid))).go();
  }

  /// 添加或更新配置信息，保留原 add/update 二段式语义。
  Future<bool> addOrUpdate(ConfigKey key, String value) async {
    final cfg = Config(key: key.name, value: value.toString(), uid: 0);
    try {
      await into(configs).insertOnConflictUpdate(
        ConfigsCompanion.insert(
          key: cfg.key,
          value: cfg.value,
          uid: cfg.uid,
        ),
      );
      return true;
    } catch (err, stack) {
      logger.error(tag, err, stack);
      return false;
    }
  }
}
