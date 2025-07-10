import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:get/get.dart';

class ClipboardSourceService extends GetxService {
  final _dbService = Get.find<DbService>();

  //appId -> AppInfo
  final _appInfos = <String, AppInfo>{}.obs;

  List<AppInfo> get appInfos => _appInfos.values.toList(growable: false)..sort((a, b) => a.name.compareTo(b.name));

  Future<ClipboardSourceService> init() async {
    await _loadAll();
    return this;
  }

  Future<void> _loadAll() async {
    final tmpMap = <String, AppInfo>{};
    var appInfos = await _dbService.appInfoDao.getAllAppInfos();
    for (var item in appInfos) {
      tmpMap[item.appId] = item;
    }
    _appInfos.clear();
    _appInfos.addAll(tmpMap);
    var idSet = tmpMap.values.map((item) => item.id).toSet();
    AppInfoExt.removeWhere((id, _) => !idSet.contains(id));
  }

  Future<bool> addOrUpdate(AppInfo appInfo, [bool notify = false]) async {
    //如果已缓存该app信息判断内容，直接返回
    if (isCached(appInfo)) {
      return true;
    }
    final data = await _dbService.appInfoDao.getByUniqueIndex(appInfo.devId, appInfo.appId);
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
    final opMethod = data == null ? OpMethod.add : OpMethod.update;
    //通知其他设备更新数据
    _dbService.opRecordDao.addAndNotify(
      OperationRecord.fromSimple(
        Module.appInfo,
        opMethod,
        appInfo.id.toString(),
      ),
    );
    return cnt > 0;
  }

  ///判断是否缓存某 app 信息
  bool isCached(AppInfo appInfo) {
    if (!_appInfos.containsKey(appInfo.appId)) {
      return false;
    }
    //判断内容是否相同（不含id）
    return appInfo.hasSameContent(_appInfos[appInfo.appId]);
  }

  AppInfo? getAppInfoByAppId(String? appId) {
    if (appId == null) return null;
    if (_appInfos.containsKey(appId)) {
      return _appInfos[appId];
    }
    return null;
  }

  Future<void> removeNotUsed() async {
    await _dbService.appInfoDao.removeNotUsed();
    await _loadAll();
  }
}
