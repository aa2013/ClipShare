import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:get/get.dart';

class Devices {
  final Map<String, Device> _devices = {};

  Devices(List<Device> devices) {}

  factory Devices.fromMap(Map<String, Device> devices) {
    var lst = devices.values.toList();
    return Devices(lst);
  }

  Device getById(String id) {
    if (_devices.containsKey(id)) {
      return _devices[id]!;
    }
    final appConfig = Get.find<ConfigService>();
    return id == appConfig.device.guid
        ? appConfig.device
        : Device.empty(devName: TranslationKey.unknown.tr);
  }

  String getName(String id) {
    return getById(id).displayName;
  }

  Devices copyWith(Device dev) {
    _devices[dev.guid] = dev;
    return Devices.fromMap(_devices);
  }

  Map<String, String> toIdNameMap() {
    Map<String, String> res = {};
    _devices.forEach((key, value) {
      res[key] = value.displayName;
    });
    return res;
  }

  List<Device> get pairedList {
    return _devices.values.where((dev) => dev.isPaired).toList();
  }
}
