import 'dart:async';

import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare/core/history/history_recorder_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_provider.g.dart';

/// 历史列表状态类型，避免 Riverpod 生成器直接展开 Drift 生成的类型
typedef HistoryList = List<History>;

/// 历史列表状态，后续由历史业务模块负责加载、追加和刷新。
@Riverpod(keepAlive: true)
class HistoriesNotifier extends _$HistoriesNotifier {
  final pageSize = 100;
  HistoryList _recentHistories = [];
  History? _latest;
  var _searching = false;

  bool get searching => _searching;

  set searching(bool value) {
    _searching = value;
    if(!_searching){
      state = _recentHistories.take(100).toList();
    }
  }

  @override
  HistoryList build() {
    unawaited(_listen());
    return _recentHistories;
  }

  Future<void> _listen() async {
    final db = await ref.read(appDbProvider.future);
    _recentHistories = await db.historyDao.getHistoriesTop100();
    final recorder = ref.read(historyRecorderProvider);
    await for (final event in recorder.events) {
      //todo 加入list
    }
  }
}
