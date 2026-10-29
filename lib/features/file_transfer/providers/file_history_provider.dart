import 'dart:async';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/history_dao.dart';
import 'package:clipshare/core/services/history/history_event.dart';
import 'package:clipshare/core/services/history/history_recorder_provider.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_history_provider.g.dart';

/// 文件历史列表状态类型，避免 Riverpod 生成器直接展开 Drift 生成的类型
typedef FileHistoryList = List<History>;

/// 文件历史列表：加载本机历史发送/接收的文件记录，
/// 订阅历史增量事件，文件类型记录增删时自动重载。
@Riverpod(keepAlive: true)
class FileHistoryNotifier extends _$FileHistoryNotifier {
  static const tag = 'FileHistoryNotifier';

  StreamSubscription<HistoryDeltaEvent>? _deltaSub;

  HistoryDao get _historyDao => ref.read(appDbProvider).requireValue.historyDao;

  HistoryRecorderNotifier get _historyRecorder => ref.read(historyRecorderProvider.notifier);

  @override
  Future<FileHistoryList> build() async {
    await _deltaSub?.cancel();
    _deltaSub = _historyRecorder.events.listen(_onDelta);
    ref.onDispose(() => _deltaSub?.cancel());
    return _historyDao.getFiles();
  }

  /// 文件类型记录发生变化时重载列表
  void _onDelta(HistoryDeltaEvent event) {
    if (event.history.type != HistoryContentType.file.value) {
      return;
    }
    ref.invalidateSelf();
  }
}
