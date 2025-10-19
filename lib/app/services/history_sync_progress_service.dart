import 'dart:async';
import 'package:clipshare/app/data/models/missing_data_sync_progress.dart';
import 'package:clipshare/app/listeners/dev_alive_listener.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/services/transport/connection_registry_service.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:get/get.dart';
import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/op_method.dart';

class HistorySyncProgressService extends GetxService with DevAliveListener {
  final connRegService = Get.find<ConnectionRegistryService>();
  static const tag = "HistorySyncProgressService";

  // devId -> progress
  final _missingDataSyncProgress = <String, MissingDataSyncProgress>{}.obs;

  //记录上次同步时间
  DateTime _lastSyncTime = DateTime.now();
  late Timer timer;

  int get syncedCnt => _missingDataSyncProgress.values.fold(0, (prev, item) => prev + item.syncedCount);

  bool get syncing => syncedCnt != total;

  int get total => _missingDataSyncProgress.values.fold(0, (prev, item) => prev + item.total);

  @override
  void onInit() {
    final duration = 10.s;
    timer = Timer.periodic(duration, (t) {
      final now = DateTime.now();
      final diff = now.difference(_lastSyncTime);
      if (diff.inSeconds > 10 && total > 0) {
        //因为某种原因进度中断了
        _missingDataSyncProgress.clear();
      }
    });
    connRegService.addDevAliveListener(this);
    super.onInit();
  }

  @override
  void onClose() {
    super.onClose();
    connRegService.removeDevAliveListener(this);
    timer.cancel();
  }

  void addProgress(String devId, Map<String, dynamic> syncData, int seq, int total) {
    MissingDataSyncProgress? newProgress;
    Module module = Module.getValue(syncData["module"]);
    final opMethod = OpMethod.getValue(syncData["method"]);

    //如果已经存在同步记录则更新或者移除
    if (_missingDataSyncProgress.containsKey(devId)) {
      var progress = _missingDataSyncProgress[devId]!;
      progress.seq = seq;
      progress.total = total;
      progress.syncedCount++;
      if (progress.firstHistory == true) {
        progress.firstHistory = false;
      } else if (module == Module.history && opMethod == OpMethod.add) {
        if (progress.firstHistory == null) {
          progress.firstHistory = true;
        } else {
          progress.firstHistory = false;
        }
      }
      newProgress = progress.copy();
      _missingDataSyncProgress[devId] = newProgress;
      if (newProgress.hasCompleted) {
        //同步完成，移除
        _missingDataSyncProgress.remove(devId);
      }
    } else if (total != 1) {
      newProgress = MissingDataSyncProgress(
        1,
        total,
        module == Module.history ? true : null,
      );
      //否则新增
      _missingDataSyncProgress[devId] = newProgress;
    }
    //如果是首条历史记录，进行复制
    if (newProgress?.firstHistory ?? false) {
      final historyController = Get.find<HistoryController>();
      try {
        historyController.setMissingDataCopyMsg(syncData);
      } catch (err, stack) {
        Log.error(tag, err, stack);
      }
    }
    _lastSyncTime = DateTime.now();
  }

  @override
  void onDisconnected(String devId) {
    _missingDataSyncProgress.remove(devId);
  }
}
