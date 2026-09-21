import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/default_settings_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/history/history_event.dart';
import 'package:clipshare/core/history/history_recorder_provider.dart';
import 'package:clipshare/shared/models/op_method.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'clip_channel_method.dart';

part 'clip_channel_provider.g.dart';
part 'clip_channel_method_call.dart';

@Riverpod(keepAlive: true)
class ClipChannelNotifier extends _$ClipChannelNotifier {
  late final MethodChannel _channel;

  @override
  void build() {
    _channel = const MethodChannel(channelClip);
    _channel.setMethodCallHandler((call) => _onMethodCall(ref, call));
  }

  ///设置置顶
  Future<bool?> setTop(int id, bool top) {
    final data = {'id': id, 'top': top};
    return _channel.invokeMethod<bool>(ClipChannelMethod.setTop.name, data);
  }

  ///设置临时文件路径（暂时只对 Windows 平台生效）
  Future<bool?> setTempDir(String dirPath) {
    if (!isWindows) return Future.value(false);
    final data = {'dirPath': dirPath};
    return _channel.invokeMethod<bool>(ClipChannelMethod.setTempDir.name, data);
  }
}
