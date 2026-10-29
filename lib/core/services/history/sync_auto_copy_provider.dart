import 'dart:async';

import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare/core/extensions/history_data_extension.dart';
import 'package:clipshare/core/platform/channels/android/android_channel_provider.dart';
import 'package:clipshare/core/platform/channels/android/events/screen_opened_event.dart';
import 'package:clipshare/core/services/history/history_event.dart';
import 'package:clipshare/core/services/history/history_recorder_provider.dart';
import 'package:clipshare/core/settings/sync/sync_settings.dart';
import 'package:clipshare/core/settings/sync/sync_settings_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_auto_copy_provider.g.dart';

///同步接收自动复制服务
@Riverpod(keepAlive: true)
class SyncAutoCopy extends _$SyncAutoCopy {
  static const tag = 'SyncAutoCopy';

  ///屏幕锁定状态：桌面端无屏幕事件，恒视为亮屏
  var _screenLocked = false;

  ///锁屏期间待复制的最新记录
  History? _pendingCopy;

  StreamSubscription<HistoryDeltaEvent>? _deltaSub;
  StreamSubscription<ScreenEvent>? _screenSub;

  HistoryRecorderNotifier get _recorder => ref.read(historyRecorderProvider.notifier);

  SyncSettings get _syncSettings => ref.read(syncSettingsProvider).requireValue;

  @override
  void build() {
    _deltaSub = _recorder.events.listen(_onDeltaEvent);
    final androidChannel = ref.read(androidChannelProvider.notifier);
    _screenSub = androidChannel.screenEvents.listen(_onScreenEvent);
    ref.onDispose(_dispose);
  }

  void _dispose() {
    _deltaSub?.cancel();
    _screenSub?.cancel();
  }

  ///处理历史 delta：仅同步落库的 add 参与自动复制
  void _onDeltaEvent(HistoryDeltaEvent event) {
    if (!event.isAdd || !event.fromSync) {
      return;
    }
    _onSyncedHistory(event.history);
  }

  ///同步到本机的历史记录统一入口：判定后亮屏立即复制，锁屏暂存等待解锁重放
  void _onSyncedHistory(History history) {
    //剪贴板只前进：比当前最新记录旧的内容不复制。
    //等值即本条就是刚推进 latest 的记录，放行
    if (history.id < (_recorder.latest?.id ?? 0)) {
      return;
    }
    final type = history.getCopyType();
    if (type == null) {
      //不可复制，跳过
      return;
    }
    //图片复制受独立开关控制
    if (type == .image && !_syncSettings.autoCopyImageAfterSync) {
      return;
    }
    if (_screenLocked) {
      //锁屏期间只保留最新一条，解锁后按设置重放
      final pending = _pendingCopy;
      if (pending == null || history.id > pending.id) {
        _pendingCopy = history;
      }
      return;
    }
    unawaited(history.copyContent());
  }

  ///屏幕状态：仅关闭/解锁影响锁定态，亮屏不改变
  void _onScreenEvent(ScreenEvent event) {
    if (event is ScreenClosedEvent) {
      _screenLocked = true;
    } else if (event is ScreenUnlockedEvent) {
      _screenLocked = false;
      _replayPendingCopy();
    }
  }

  ///解锁重放：按设置复制锁屏期间收到的最新记录
  void _replayPendingCopy() {
    final pending = _pendingCopy;
    _pendingCopy = null;
    if (pending == null || !_syncSettings.reCopyOnScreenUnlocked) {
      return;
    }
    //解锁期间内容可能已被本机更新，仍比最新旧则不再回退剪贴板
    if (pending.id < (_recorder.latest?.id ?? 0)) {
      return;
    }
    unawaited(pending.copyContent());
  }
}
