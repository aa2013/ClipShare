import 'package:clipshare/app/data/enums/config_key.dart';
import 'package:clipshare/app/data/repository/entity/tables/config.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:floor/floor.dart';
import 'package:get/get.dart';

@dao
abstract class ConfigDao {
  static const tag = "ConfigDao";

  ///获取所有配置项
  @Query("select * from config where uid = :uid")
  Future<List<Config>> getAllConfigs(int uid);

  ///获取某个配置项
  @Query("select `value` from config where `key` = :key and uid = :uid")
  Future<String?> getConfig(String key, int uid);

  ///获取某个配置项
  Future<T> getConfigByKey<T>(ConfigKey key, T defValue, {T Function(String value)? convert}) async {
    final value = await getConfig(key.name, 0);
    if (value == null || value.isEmpty) {
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

  ///添加一个配置
  @insert
  Future<int> add(Config config);

  ///更新配置
  @update
  Future<int> updateConfig(Config config);

  ///删除配置
  @delete
  Future<int> remove(Config config);

  ///根据 key 删除配置
  @Query("delete from config where key = :key and uid = :uid")
  Future<void> removeByKey(String key, int uid);

  ///添加或更新配置信息
  Future<bool> addOrUpdate(ConfigKey key, String value) async {
    var v = await getConfig(key.name, 0);
    var cfg = Config(key: key.name, value: value.toString(), uid: 0);
    try {
      if (v == null) {
        return await add(cfg) > 0;
      } else {
        return await updateConfig(cfg) > 0;
      }
    } catch (err, stack) {
      Log.error(tag, err, stack);
      return false;
    }
  }
}
