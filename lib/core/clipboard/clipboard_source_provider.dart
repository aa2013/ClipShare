import 'dart:async';
import 'dart:convert';

import 'package:clipshare/core/app_selection/local_app_info.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/app_info_dao.dart';
import 'package:clipshare/core/database/dao/operation_record_dao.dart';
import 'package:clipshare/core/database/tables/app_info.dart';
import 'package:clipshare/core/database/tables/operation_record.dart';
import 'package:clipshare/core/device/local_device_info.dart';
import 'package:clipshare/core/local_device/local_device_info_provider.dart';
import 'package:clipshare/core/snowflake/id_provider.dart';
import 'package:clipshare/core/utils/snowflake.dart';
import 'package:clipshare/shared/models/module.dart';
import 'package:clipshare/shared/models/op_method.dart';
import 'package:flutter/foundation.dart';
import 'package:get_apps/get_apps.dart' show GetApps;
import 'package:get_apps/models.dart' as get_apps;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clipboard_source_provider.g.dart';

/// 剪贴板来源状态模型
@immutable
class ClipboardSourceState {
  /// 已同步的来源库：appId -> AppInfo
  final Map<String, AppInfo> _appInfos;

  /// 本机已安装应用：appId -> LocalAppInfo（仅 Android，非持久化）
  final Map<String, LocalAppInfo> _installedApps;

  const ClipboardSourceState({
    required Map<String, AppInfo> appInfos,
    required Map<String, LocalAppInfo> installedApps,
  }) : _appInfos = appInfos,
       _installedApps = installedApps;

  /// 来源列表（按名称排序）
  List<AppInfo> get appInfos {
    return _appInfos.values.toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// 本机已安装应用列表
  List<LocalAppInfo> get installedApps {
    return _installedApps.values.toList(growable: false);
  }

  /// 判断是否已缓存同 appId 且内容一致的来源
  bool isCached(AppInfo appInfo) {
    if (!_appInfos.containsKey(appInfo.appId)) {
      return false;
    }
    return appInfo.hasSameContent(_appInfos[appInfo.appId]);
  }

  /// 按 appId 查找来源：先命中来源库，未命中再回退本机已安装应用
  AppInfo? getAppInfoByAppId(String? appId) {
    if (appId == null) {
      return null;
    }
    if (_appInfos.containsKey(appId)) {
      return _appInfos[appId];
    }
    if (_installedApps.containsKey(appId)) {
      return _installedApps[appId];
    }
    return null;
  }
}

@Riverpod(keepAlive: true)
class ClipboardSourceNotifier extends _$ClipboardSourceNotifier {
  final _getAppsHelper = GetApps();
  StreamSubscription<get_apps.ActionNotification>? _appInstallStream;

  AppInfoDao get _appInfoDao => ref.read(appDbProvider).requireValue.appInfoDao;

  OperationRecordDao get _opRecordDao => ref.read(appDbProvider).requireValue.operationRecordDao;

  Snowflake get _snowflake => ref.read(idProvider);

  BaseDeviceInfo get _baseDevInfo => ref.read(localDeviceInfoProvider).requireValue.baseDeviceInfo;

  /// 当前来源状态基准（state 尚未就绪时返回空数据）
  ClipboardSourceState get _current =>
      state.value ??
      const ClipboardSourceState(
        appInfos: <String, AppInfo>{},
        installedApps: <String, LocalAppInfo>{},
      );

  @override
  Future<ClipboardSourceState> build() async {
    final appInfos = await _queryAppInfos();
    // 已安装应用枚举比较耗时，此处不阻塞首屏；完成后自行刷新 state
    unawaited(_loadInstalledApps());
    return ClipboardSourceState(
      appInfos: appInfos,
      installedApps: const <String, LocalAppInfo>{},
    );
  }

  /// 查询来源库，并清理已被删除来源的图标字节缓存
  Future<Map<String, AppInfo>> _queryAppInfos() async {
    final appInfos = await _appInfoDao.getAllAppInfos();
    final appInfosByAppId = <String, AppInfo>{};
    for (var item in appInfos) {
      appInfosByAppId[item.appId] = item;
    }
    // 清理已被删除来源的图标字节缓存，避免长期持有失效图片
    AppInfoExt.removeWhere((appId, _) => !appInfosByAppId.containsKey(appId));
    return appInfosByAppId;
  }

  /// 从数据库重载来源并触发刷新
  Future<void> _reloadFromDb() async {
    final appInfos = await _queryAppInfos();
    state = AsyncData(ClipboardSourceState(
      appInfos: appInfos,
      installedApps: _current._installedApps,
    ));
  }

  /// 枚举本机已安装应用，并监听应用安装/卸载事件（仅 Android）
  Future<void> _loadInstalledApps() async {
    if (!isAndroid) {
      return;
    }
    final allApps = await _getAppsHelper.getApps();
    final userAppIds = allApps
        .where((item) => !item.isSystemApp)
        .map((item) => item.appPackage)
        .toList();
    final installed = <String, LocalAppInfo>{};
    for (var item in allApps) {
      installed[item.appPackage] = LocalAppInfo(
        isSystemApp: !userAppIds.contains(item.appPackage),
        id: 0,
        appId: item.appPackage,
        devId: _baseDevInfo.id,
        name: item.appName,
        iconB64: base64Encode(item.appIcon),
      );
    }
    state = AsyncData(ClipboardSourceState(
      appInfos: _current._appInfos,
      installedApps: installed,
    ));
    if (_appInstallStream == null) {
      _appInstallStream = _getAppsHelper.appActionReceiver().listen((_) {
        unawaited(_loadInstalledApps());
      });
      ref.onDispose(() => _appInstallStream?.cancel());
    }
  }

  /// 新增或更新来源；[notify] 为 true 时写入同步操作记录
  Future<bool> addOrUpdate(AppInfo appInfo, [bool notify = false]) async {
    // 已缓存同 appId 且内容一致，直接视为成功
    if (_current.isCached(appInfo)) {
      return true;
    }
    final data = await _appInfoDao.getByUniqueIndex(
      appInfo.devId,
      appInfo.appId,
    );
    final savedAppInfo = data != null &&
            appInfo.iconB64.isEmpty &&
            data.iconB64.isNotEmpty
        // 远端可能只同步到来源名称，不能用空图标覆盖本地已有有效图标
        ? AppInfo(
            id: appInfo.id,
            appId: appInfo.appId,
            devId: appInfo.devId,
            name: appInfo.name,
            iconB64: data.iconB64,
          )
        : appInfo;
    var cnt = 0;
    if (data == null) {
      cnt = await _appInfoDao.addAppInfo(savedAppInfo);
    } else {
      cnt = await _appInfoDao.updateAppInfo(savedAppInfo);
    }
    final success = cnt > 0;
    if (!success) {
      return false;
    }
    final current = _current;

    current._appInfos[savedAppInfo.appId] = savedAppInfo;
    state = AsyncData(ClipboardSourceState(
      appInfos: current._appInfos,
      installedApps: current._installedApps,
    ));
    if (!notify) {
      return success;
    }
    // 通知其他设备同步数据
    final opMethod = data == null ? OpMethod.add : OpMethod.update;
    await _opRecordDao.addAndNotify(
      newOperationRecord(
        _snowflake,
        _baseDevInfo,
        Module.appInfo,
        opMethod,
        savedAppInfo.id,
      ),
    );
    return success;
  }

  /// 清理无历史记录引用的来源，并重载来源库
  Future<void> removeNotUsed() async {
    await _appInfoDao.removeNotUsed();
    await _reloadFromDb();
  }
}