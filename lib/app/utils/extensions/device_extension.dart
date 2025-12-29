import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/enums/transport_protocol.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/modules/device_module/device_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/transport/socket_service.dart';
import 'package:clipshare/app/services/transport/storage_service.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:get/get.dart';

extension DeviceExt on Device {
  bool get isUseForwardServer {
    final appConfig = Get.find<ConfigService>();
    if (appConfig.forwardServer == null) {
      return false;
    }

    return address == appConfig.forwardServer!.server;
  }

  bool get isUseWebDAV {
    return address == TransportProtocol.webdav.name;
  }

  bool get isUseS3 {
    return address == TransportProtocol.s3.name;
  }

  bool get isUseDirect {
    return !isUseForwardServer && !isUseS3 && !isUseWebDAV;
  }

  bool get isUseStorage {
    return isUseWebDAV || isUseS3;
  }

  TransportProtocol get protocol {
    if (isUseWebDAV) return TransportProtocol.webdav;
    if (isUseS3) return TransportProtocol.s3;
    if (isUseForwardServer) return TransportProtocol.server;
    return TransportProtocol.direct;
  }

  Future<void> sendData(MsgType key, Map<String, dynamic> data, [bool onlyPaired = true]) {
    return DevInfo.fromDevice(this).sendData(key, data, onlyPaired);
  }
}

extension DevInfoExt on DevInfo {
  static const tag = "DevInfoExt";

  Future<void> sendData(MsgType key, Map<String, dynamic> data, [bool onlyPaired = true]) async {
    final devController = Get.find<DeviceController>();
    final list = devController.onlineList.where((dev) => onlyPaired ? dev.isPaired : true).toList();
    final dev = list.firstWhereOrNull((item) => item.guid == guid);
    if (dev == null) {
      Log.warn(tag, "device is offline or not exists");
      return;
    }
    if (dev.isUseForwardServer || dev.isUseDirect) {
      final sktService = Get.find<SocketService>();
      return sktService.sendData(this, key, data, onlyPaired);
    } else {
      final storageService = Get.find<StorageService>();
      return storageService.sendData(this, key, data, onlyPaired);
    }
  }
}
