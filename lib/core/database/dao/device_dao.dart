import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_tables.dart';
import 'package:drift/drift.dart';

part 'device_dao.g.dart';

@DriftAccessor(tables: [Devices])
class DeviceDao extends DatabaseAccessor<AppDatabase> with _$DeviceDaoMixin {
  DeviceDao(super.attachedDatabase);

  /// 获取指定用户的所有设备。
  Future<List<Device>> getAllDevices(int uid) {
    return (select(devices)..where((tbl) => tbl.uid.equals(uid))).get();
  }

  /// 根据设备 id 和用户 id 获取设备信息。
  Future<Device?> getById(String guid, int uid) {
    return (select(devices)..where((tbl) => tbl.guid.equals(guid) & tbl.uid.equals(uid))).getSingleOrNull();
  }

  /// 添加设备，保持旧主键冲突时抛错的语义。
  Future<int> add(Device dev) {
    return into(devices).insert(_companion(dev));
  }

  /// 重命名设备展示名称。
  Future<int?> rename(String guid, String name, int uid) {
    return (update(devices)..where((tbl) => tbl.guid.equals(guid) & tbl.uid.equals(uid))).write(
      DevicesCompanion(customName: Value(name)),
    );
  }

  /// 更新设备完整信息。
  Future<int> updateDevice(Device dev) {
    return (update(devices)..where((tbl) => tbl.guid.equals(dev.guid))).write(_companion(dev));
  }

  /// 删除指定设备。
  Future<int?> remove(String guid, int uid) {
    return (delete(devices)..where((tbl) => tbl.guid.equals(guid) & tbl.uid.equals(uid))).go();
  }

  /// 删除指定用户的全部设备。
  Future<int?> removeAll(int uid) {
    return (delete(devices)..where((tbl) => tbl.uid.equals(uid))).go();
  }

  /// 更新设备当前连接地址。
  Future<int?> updateDeviceAddress(String guid, int uid, String address) {
    return (update(devices)..where((tbl) => tbl.guid.equals(guid) & tbl.uid.equals(uid))).write(
      DevicesCompanion(address: Value(address)),
    );
  }

  /// 更新设备内网连接地址。
  Future<int?> updateDeviceInternalAddress(String guid, int uid, String address) {
    return (update(devices)..where((tbl) => tbl.guid.equals(guid) & tbl.uid.equals(uid))).write(
      DevicesCompanion(internalAddress: Value(address)),
    );
  }

  /// 将领域设备对象转换成 Drift Companion，统一 bool/null 写入规则。
  DevicesCompanion _companion(Device dev) {
    return DevicesCompanion.insert(
      guid: dev.guid,
      devName: dev.devName,
      uid: dev.uid,
      customName: Value(dev.customName),
      type: dev.type,
      address: Value(dev.address),
      internalAddress: Value(dev.internalAddress),
      isPaired: dev.isPaired,
    );
  }
}
