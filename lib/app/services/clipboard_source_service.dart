import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/models/local_app_info.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart' as my_app_info;
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:get/get.dart';
import 'package:get_apps/get_apps.dart';
import 'package:get_apps/models.dart';

typedef MyAppInfo = my_app_info.AppInfo;

class ClipboardSourceService extends GetxService {
  final _dbService = Get.find<DbService>();
  final _appConfig = Get.find<ConfigService>();
  final _getAppsHelper = GetApps();
  Stream<ActionNotification>? _appInstallStream;

  //appId -> MyAppInfo
  final _appInfos = <String, MyAppInfo>{}.obs;

  //appId -> LocalAppInfo
  final _installedApps = <String, LocalAppInfo>{}.obs;

  List<LocalAppInfo> get installedApps => _installedApps.values.toList();

  List<MyAppInfo> get appInfos => _appInfos.values.toList(growable: false)..sort((a, b) => a.name.compareTo(b.name));

  Future<ClipboardSourceService> init() async {
    await _loadAll();
    return this;
  }

  Future<void> _loadAll() async {
    await _loadClipboardSource();
    //这里不要await，否则会占用大量时间导致应用卡第一屏
    _loadInstalledApps();
  }

  Future<void> _loadClipboardSource() async {
    final tmpMap = <String, MyAppInfo>{};
    var appInfos = await _dbService.appInfoDao.getAllAppInfos();
    for (var item in appInfos) {
      tmpMap[item.appId] = item;
    }
    _appInfos.clear();
    _appInfos.addAll(tmpMap);
    var idSet = tmpMap.values.map((item) => item.appId).toSet();
    my_app_info.AppInfoExt.removeWhere((appId, _) => !idSet.contains(appId));
  }

  Future<void> _loadInstalledApps() async {
    if (!Platform.isAndroid) {
      return;
    }
    _installedApps.clear();
    final allApps = await _getAppsHelper.getApps();
    final userAppIds = allApps.where((item) => !item.isSystemApp).map((item) => item.appPackage).toList();
    for (var item in allApps) {
      _installedApps[item.appPackage] = LocalAppInfo(
        isSystemApp: !userAppIds.contains(item.appPackage),
        id: 0,
        appId: item.appPackage,
        devId: _appConfig.device.guid,
        name: item.appName,
        iconB64: base64Encode(item.appIcon),
      );
    }
    if (_appInstallStream == null) {
      _appInstallStream = _getAppsHelper.appActionReceiver();
      _appInstallStream!.listen((notification) async {
        _loadInstalledApps();
      });
    }
  }

  Future<bool> addOrUpdate(MyAppInfo appInfo, [bool notify = false]) async {
    //如果已缓存该app信息，直接返回
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
  bool isCached(MyAppInfo appInfo) {
    if (!_appInfos.containsKey(appInfo.appId)) {
      return false;
    }
    //判断内容是否相同（不含id）
    return appInfo.hasSameContent(_appInfos[appInfo.appId]);
  }

  MyAppInfo? getAppInfoByAppId(String? appId) {
    if (appId == null) return null;
    if (_appInfos.containsKey(appId)) {
      return _appInfos[appId];
    }
    if (_installedApps.containsKey(appId)) {
      return _installedApps[appId];
    }
    return null;
  }

  Future<void> removeNotUsed() async {
    await _dbService.appInfoDao.removeNotUsed();
    await _loadClipboardSource();
  }
}
