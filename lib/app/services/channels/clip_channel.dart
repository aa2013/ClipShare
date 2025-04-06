import 'dart:io';

import 'package:clipshare/app/services/config_service.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ClipChannelMethod {
  ClipChannelMethod._private();

  static const getHistory = "getHistory";
  static const setTop = "setTop";
  static const ignoreNextCopy = "ignoreNextCopy";
  static const setTempDir = "setTempDir";
}

class ClipChannelService extends GetxService {
  late final MethodChannel clipChannel;

  ClipChannelService init() {
    final appConfig = Get.find<ConfigService>();
    clipChannel = appConfig.clipChannel;
    return this;
  }

  ///设置置顶
  Future<bool?> setTop(int id, bool top) {
    final data = {"id": id, "top": top};
    return clipChannel.invokeMethod<bool>(ClipChannelMethod.setTop, data);
  }

  ///设置临时文件路径（暂时只对 Windows 平台生效）
  Future<bool?> setTempDir(String dirPath) {
    if (!Platform.isWindows) return Future.value(false);
    final data = {"dirPath": dirPath};
    return clipChannel.invokeMethod<bool>(ClipChannelMethod.setTempDir, data);
  }
}
