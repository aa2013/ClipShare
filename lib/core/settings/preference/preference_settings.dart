import 'dart:ui';

import 'package:clipshare/core/constants/default_settings_constants.dart';

class PreferenceSettings {
  ///记住窗口大小
  final bool rememberWindowSize;

  ///窗口大小
  final Size windowSize;

  ///（Android）是否在最近任务展示
  final bool showOnRecentTasks;

  ///在一行中显示更多项
  final bool showMoreItemsInRow;

  ///设备连接变化是托盘闪烁
  final bool useTrayFlashingForConnection;

  ///记住历史弹窗位置
  final bool recordHistoryDialogPosition;

  ///历史记录弹窗位置
  final Offset? historyDialogPosition;

  ///记住弹窗尺寸
  final bool rememberPopupWindowSize;

  ///历史记录弹窗尺寸
  final Size? historyWindowSize;

  ///文件发送弹窗尺寸
  final Size? fileSenderWindowSize;

  ///失焦自动关闭
  final bool autoClosePopupOnBlur;

  ///相同快捷键关闭
  final bool closeOnSameHotKey;

  ///桌面端历史弹窗粘贴触发行为，默认双击
  final bool clickToPaste;

  ///上次 Sql 编辑内容
  final String lastSqlEditContent;

  const PreferenceSettings({
    this.rememberWindowSize = false,
    this.windowSize = defaultWindowSize,
    this.showOnRecentTasks = true,
    this.showMoreItemsInRow = true,
    this.useTrayFlashingForConnection = false,
    this.recordHistoryDialogPosition = false,
    this.historyDialogPosition,
    this.rememberPopupWindowSize = false,
    this.historyWindowSize,
    this.fileSenderWindowSize,
    this.autoClosePopupOnBlur = false,
    this.closeOnSameHotKey = false,
    this.clickToPaste = false,
    this.lastSqlEditContent = '',
  });
}
