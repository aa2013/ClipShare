import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:floor/floor.dart';

@dao
abstract class DeviceDao {
  ///获取所有设备
  @Query("select * from device where uid = :uid")
  Future<List<Device>> getAllDevices(int uid);

  ///根据设备id获取设备信息
  @Query("select * from device where guid = :guid and uid = :uid")
  Future<Device?> getById(String guid, int uid);

  ///添加一个设备
  @insert
  Future<int> add(Device dev);

  ///重命名设备名
  @Query(
    "update device set customName = :name where uid = :uid and guid = :guid",
  )
  Future<int?> rename(String guid, String name, int uid);

  ///更新设备信息
  @update
  Future<int> updateDevice(Device dev);

  ///删除设备
  @Query("delete from device where guid = :guid and uid = :uid")
  Future<int?> remove(String guid, int uid);

  ///删除所有设备
  @Query("delete from device where uid = :uid")
  Future<int?> removeAll(int uid);

  ///更新设备当前连接地址
  @Query(
    "update device set address = :address where uid = :uid and guid = :guid",
  )
  Future<int?> updateDeviceAddress(String guid, int uid, String address);
}
