import 'package:clipshare_clipboard_listener/enums.dart';

class ClipboardSettings {
  ///Android 屏幕关闭后停止监听
  final bool stopListeningOnScreenClosed;

  ///来源记录
  final bool sourceRecord;

  ///Android 通过dumpsys记录来源（兜底）
  final bool sourceRecordViaDumpsys;

  ///Android 新数据来后发送广播
  final bool sendBroadcastOnAdd;

  ///Windows 过滤排除格式
  final bool isExcludeFormat;

  ///记录最大长度，超出丢弃
  final int recordMaxLength;

  ///Android 工作模式
  final EnvironmentType workingMode;

  ///Android 剪贴板监听方式
  final ClipboardListeningWay listeningWay;

  const ClipboardSettings({
    this.stopListeningOnScreenClosed = false,
    this.sourceRecord = false,
    this.sourceRecordViaDumpsys = false,
    this.sendBroadcastOnAdd = false,
    this.isExcludeFormat = true,
    this.recordMaxLength = 200000,
    this.workingMode = EnvironmentType.none,
    this.listeningWay = ClipboardListeningWay.logs,
  });
}
