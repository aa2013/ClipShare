import 'package:clipshare/core/database/tables/app_info.dart';

/// 本地应用信息：在 [AppInfo] 基础上补充是否为系统应用，供应用选择页分组展示。
class LocalAppInfo extends AppInfo {
  /// 是否为系统应用
  final bool isSystemApp;

  const LocalAppInfo({
    required this.isSystemApp,
    required super.id,
    required super.appId,
    required super.devId,
    required super.name,
    required super.iconB64,
  });

  /// 由历史来源 [AppInfo] 转换得到，[isSystemApp] 需由调用方判定。
  factory LocalAppInfo.fromAppInfo(AppInfo appInfo, bool isSystemApp) {
    return LocalAppInfo(
      isSystemApp: isSystemApp,
      id: appInfo.id,
      appId: appInfo.appId,
      devId: appInfo.devId,
      name: appInfo.name,
      iconB64: appInfo.iconB64,
    );
  }
}
