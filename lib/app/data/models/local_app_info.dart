import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';

class LocalAppInfo extends AppInfo {
  final bool isSystemApp;

  LocalAppInfo({
    required this.isSystemApp,
    required super.id,
    required super.appId,
    required super.devId,
    required super.name,
    required super.iconB64,
  });

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
