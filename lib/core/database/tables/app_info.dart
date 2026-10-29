import 'dart:convert';
import 'dart:typed_data';

import 'package:clipshare/shared/constants/assets.dart';

import '../app_database.dart';

export '../app_database.dart' show AppInfo;

/// 应用来源行对象的业务扩展，真实数据类由 Drift 生成。
extension AppInfoExt on AppInfo {
  static final _bytes = Expando<Uint8List>('appIconBytes');

  /// 按不可变实例缓存解码结果，缓存随实例回收；空图标使用公共透明图片。
  Uint8List get iconBytes {
    final content = iconB64;
    if (content.isEmpty) {
      return emptyPngBytes;
    }
    final cached = _bytes[this];
    if (cached != null) {
      return cached;
    }
    final bytes = base64.decode(content);
    _bytes[this] = bytes;
    return bytes;
  }

  /// 判断应用来源内容是否一致，id 不参与内容变更判断。
  bool hasSameContent(AppInfo? appInfo) {
    if (appInfo == null) return false;
    return appInfo.appId == appId && appInfo.devId == devId && appInfo.name == name && appInfo.iconB64 == iconB64;
  }
}
