import 'package:clipshare/core/constants/app_constants.dart';

class FloatWindowSettings {
  ///Android 启用 1px 悬浮窗增强保活
  final bool enhanceBackgroundKeepAlive;

  ///Android 是否显示历史记录悬浮窗
  final bool showHistoryFloat;

  /// Android 历史记录悬浮窗把手宽度
  final int historyFloatHandleWidth;

  ///Android 历史记录悬浮窗把手颜色
  final int historyFloatHandleColor;

  ///Android 历史记录悬浮窗把手透明度是否应用到装饰层
  final bool historyFloatHandleApplyAlphaToWholeHandle;

  ///Android 是否锁定历史记录悬浮窗
  final bool lockHistoryFloatLoc;

  ///IOS 是否启用画中画
  final bool enablePIP;

  const FloatWindowSettings({
    this.enhanceBackgroundKeepAlive = false,
    this.showHistoryFloat = false,
    this.historyFloatHandleWidth = defaultHistoryFloatHandleWidth,
    this.historyFloatHandleColor = defaultHistoryFloatHandleColor,
    this.historyFloatHandleApplyAlphaToWholeHandle = false,
    this.lockHistoryFloatLoc = false,
    this.enablePIP = false,
  });
}
