import 'dart:convert';
import 'dart:typed_data';

import 'package:clipshare/shared/constants/assets.dart';

import '../app_database.dart';

export '../app_database.dart' show AppInfo;

/// 应用来源行对象的业务扩展，真实数据类由 Drift 生成。
extension AppInfoExt on AppInfo {
  static final Map<String, Uint8List> _bytes = {};

  /// 按 appId 清理图标缓存，避免来源删除后继续持有旧图标字节。
  static void removeWhere(bool Function(String, Uint8List) func) {
    return _bytes.removeWhere(func);
  }

  /// 解码应用图标，空图标使用内置透明图片兜底。
  Uint8List get iconBytes {
    if (!_bytes.containsKey(appId)) {
      if (iconB64.isEmpty) {
        return emptyPngBytes;
      } else {
        final bytes = base64.decode(iconB64);
        _bytes[appId] = bytes;
      }
    }
    return _bytes[appId]!;
  }

  /// 判断应用来源内容是否一致，id 不参与内容变更判断。
  bool hasSameContent(AppInfo? appInfo) {
    if (appInfo == null) return false;
    return appInfo.appId == appId && appInfo.devId == devId && appInfo.name == name && appInfo.iconB64 == iconB64;
  }
}
