import 'package:clipshare_clipboard_listener/enums.dart';

extension ClipboardEnvTypeExtension on EnvironmentType {
  /// 是否提供监听方式切换：只有 Shizuku / root 特权环境才能使用隐藏 API 监听
  bool get showListeningWay {
    return this == EnvironmentType.shizuku || this == EnvironmentType.root;
  }
}
