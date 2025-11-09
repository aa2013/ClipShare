import 'package:clipshare/app/data/enums/forward_way.dart';
import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/enums/transport_protocol.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/listeners/sync_listener.dart';
import 'package:clipshare/app/modules/device_module/device_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/transport/storage_service.dart';
import 'package:clipshare/app/utils/extensions/device_extension.dart';
import 'package:get/get.dart';

abstract mixin class DataSender {
  static final Map<Module, List<SyncListener>> _syncListeners = {};

  Future<void> sendData(
    DevInfo? dev,
    MsgType key,
    Map<String, dynamic> data, [
    bool onlyPaired = true,
  ]);

  static Future<void> sendData2All(
    MsgType key,
    Map<String, dynamic> data, [
    bool onlyPaired = true,
  ]) async {
    final devController = Get.find<DeviceController>();
    final appConfig = Get.find<ConfigService>();
    //如果当前中转方式为存储服务，先写入存储，后续再通知设备
    if (ForwardWay.storageWays.contains(appConfig.forwardWay)) {
      final storageService = Get.find<StorageService>();
      //如果无已配对的在线设备，且使用的存储服务，则直接写入存储不对设备发送通知
      if (devController.onlineAndPairedList.isEmpty) {
        await storageService.sendData(null, key, data);
        return;
      }
    }
    //对在线设备发送数据
    final onlineList = devController.onlineList;
    for (var dev in onlineList) {
      await dev.sendData(key, data, onlyPaired);
    }
  }

  ///通过设备 id 发送数据
  static Future<void> sendDataByDevId(
    String devId,
    MsgType key,
    Map<String, dynamic> data, [
    bool onlyPaired = true,
  ]) {
    final devController = Get.find<DeviceController>();
    final list = devController.onlineList.where((dev) => onlyPaired ? dev.isPaired : true).toList();
    final dev = list.firstWhereOrNull((item) => item.guid == devId);
    if (dev == null) {
      return Future.value();
    }
    return dev.sendData(key, data, onlyPaired);
  }

  List<SyncListener> getListeners(Module module) {
    final list = _syncListeners[module];
    return List.from(list ?? []);
  }

  ///添加同步监听
  static void addSyncListener(Module module, SyncListener listener) {
    if (_syncListeners.keys.contains(module)) {
      _syncListeners[module]!.add(listener);
      return;
    }
    _syncListeners[module] = List.empty(growable: true);
    _syncListeners[module]!.add(listener);
  }

  ///移除同步监听
  static void removeSyncListener(Module module, SyncListener listener) {
    _syncListeners[module]?.remove(listener);
  }
}
