import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:get/get.dart';

class ClipboardSourceService extends GetxService {
  final _dbService = Get.find<DbService>();
  final _appConfig = Get.find<ConfigService>();

  //appId -> AppInfo
  final _appInfos = <String, AppInfo>{}.obs;

  List<AppInfo> get appInfos => _appInfos.values.toList(growable: false)..sort((a, b) => a.name.compareTo(b.name));

  Future<ClipboardSourceService> init() async {
    var appInfos = await _dbService.appInfoDao.getAllAppInfos();
    for (var item in appInfos) {
      _appInfos[item.appId] = item;
    }
    return this;
  }

  Future<bool> addOrUpdate(AppInfo appInfo, [bool notify = false]) async {
    final data = await _dbService.appInfoDao.getById(appInfo.id);
    var cnt = 0;
    if (data == null) {
      cnt = await _dbService.appInfoDao.addAppInfo(appInfo);
    } else {
      cnt = await _dbService.appInfoDao.updateAppInfo(appInfo);
    }
    final success = cnt > 0;
    if (!success) {
      return false;
    }
    _appInfos[appInfo.appId] = appInfo;
    if (!notify) {
      return success;
    }
    //通知其他设备更新数据
    _dbService.opRecordDao.addAndNotify(
      OperationRecord.fromSimple(
        Module.appInfo,
        data == null ? OpMethod.add : OpMethod.update,
        appInfo.id.toString(),
      ),
    );
    return cnt > 0;
  }

  bool contains(String appId) {
    return _appInfos.containsKey(appId);
  }

  AppInfo? getAppInfoByAppId(String appId) {
    if (_appInfos.containsKey(appId)) {
      return _appInfos[appId];
    }
    return null;
  }
}
