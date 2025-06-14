import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipboard_listener/clipboard_manager.dart';
import 'package:clipboard_listener/enums.dart';
import 'package:clipboard_listener/models/clipboard_source.dart';
import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/data/models/message_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/data/repository/entity/tables/history_tag.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_sync.dart';
import 'package:clipshare/app/listeners/history_data_listener.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/channels/clip_channel.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:clipshare/app/services/tag_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/extensions/time_extension.dart';
import 'package:clipshare/app/utils/file_util.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/permission_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:synchronized/synchronized.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class HistoryController extends GetxController with WidgetsBindingObserver implements HistoryDataObserver, SyncListener {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final sktService = Get.find<SocketService>();
  final multiWindowChannelService = Get.find<MultiWindowChannelService>();
  final androidChannelService = Get.find<AndroidChannelService>();
  final clipChannelService = Get.find<ClipChannelService>();
  final sourceService = Get.find<ClipboardSourceService>();
  final tagService = Get.find<TagService>();

  //region 属性
  final String tag = "HistoryController";

  ///不要直接操作这个list，请操作 _tempList 并执行 debounceUpdate() 方法以进行防抖更新
  final list = List<ClipData>.empty(growable: true).obs;

  ///需要更新并复制的最新的数据 id
  int? _missingDataCopyMsg;

  ///onChange事件锁
  final _onChangeLock = Lock();

  ///获取最新的一条数据，如果 tmpList和 list都有数据就判断时间，否则返回不为空的
  History? get last {
    var tmpSortedList = [..._tempList];
    tmpSortedList.sort((a, b) => b.data.id.compareTo(a.data.id));
    final tmpLast = tmpSortedList.isEmpty ? null : tmpSortedList[0];
    tmpSortedList = [...list];
    tmpSortedList.sort((a, b) => b.data.id.compareTo(a.data.id));
    final lstLast = list.isEmpty ? null : list[0].data;
    if (tmpLast == null && lstLast == null) return null;
    if (tmpLast != null && lstLast != null) {
      if (DateTime.parse(tmpLast.data.time).isAfter(DateTime.parse(lstLast.time))) {
        return tmpLast.data;
      } else {
        return lstLast;
      }
    }
    if (tmpLast != null) return tmpLast.data;
    return lstLast;
  }

  bool updating = false;
  final _loading = true.obs;

  bool get loading => _loading.value;
  Timer? _debounce;

  //防止短时间内频繁刷新ui的临时缓冲列表
  final List<ClipData> _tempList = List.empty(growable: true);

  //endregion

  //region 生命周期
  @override
  void onInit() {
    super.onInit();
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
    //更新上次复制的记录
    updateLatestLocalClip().then((his) {
      //添加同步监听
      sktService.addSyncListener(Module.history, this);
      //刷新列表
      refreshData();
      //剪贴板监听注册
      HistoryDataListener.inst.register(this);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && Platform.isAndroid) {
      debounceUpdate();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    sktService.removeSyncListener(Module.history, this);
    super.dispose();
  }

  //endregion

  //region 页面方法
  ///移除数据
  void removeById(int id) {
    _tempList.removeWhere(
      (item) => item.data.id == id,
    );
    debounceUpdate();
  }

  ///更新页面数据
  void updateData(
    bool Function(History history) where,
    void Function(History history) cb, [
    bool shouldRefresh = false,
  ]) {
    for (var i = 0; i < _tempList.length; i++) {
      final item = _tempList[i];
      //查找符合条件的数据
      if (where(item.data)) {
        //更新数据
        cb(item.data);
      }
    }
    if (shouldRefresh) {
      refreshData();
    } else {
      debounceUpdate();
    }
  }

  ///重新加载列表
  Future<void> refreshData() {
    return dbService.historyDao.getHistoriesTop100(appConfig.userId).then((lst) {
      _tempList.assignAll(ClipData.fromList(lst));
      debounceUpdate();
    });
  }

  ///更新上次复制的内容
  Future<History?> updateLatestLocalClip() {
    return dbService.historyDao.getLatestLocalClip(appConfig.userId);
  }

  ///防抖更新页面
  void debounceUpdate() {
    // 如果已有计时器，则取消它
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    // 重新设置计时器，延迟 200 毫秒执行
    _debounce = Timer(const Duration(milliseconds: 200), () {
      final lst = [..._tempList];
      lst.sort((a, b) => b.data.compareTo(a.data));
      list.assignAll(lst);
      if (loading) {
        _loading.value = false;
      }
    });
  }

  ///通知子窗体更新
  void notifyHistoryWindow() {
    if (PlatformExt.isMobile) return;
    if (appConfig.historyWindow == null) return;
    multiWindowChannelService.notify(appConfig.historyWindow!.windowId).catchError((err) {
      if (err.toString().contains("target window not found")) {
        appConfig.historyWindow = null;
      } else {
        Log.error(tag, err);
      }
    });
  }

  ///更新并复制最新的数据
  ///场景：同步缺失数据时，如果同步到最新（比当前本地的）的数据就自动复制
  void setMissingDataCopyMsg(MessageData msg) {
    final syncData = msg.data["data"];
    Map<dynamic, dynamic> data = {};
    if (syncData is String) {
      data = jsonDecode(syncData);
    } else {
      data = syncData;
    }
    final historyMap = data.cast<String, dynamic>();
    final history = History.fromJson(historyMap);
    _missingDataCopyMsg = history.id;
  }

  //endregion

  //region 同步与监听
  @override
  Future ackSync(MessageData msg) async {
    var send = msg.send;
    var data = msg.data;
    var opSync = OperationSync(
      opId: data["id"],
      devId: send.guid,
      uid: appConfig.userId,
    );
    //记录同步记录
    await dbService.opSyncDao.add(opSync);
    //更新本地历史记录为已同步
    var hisId = msg.data["hisId"];
    return dbService.historyDao.setSync(hisId, true).then((_) {
      for (var clip in _tempList) {
        if (clip.data.id.toString() == hisId.toString()) {
          clip.data.sync = true;
          debounceUpdate();
          break;
        }
      }
    });
  }

  Future f = Future.value();

  @override
  Future<void> onChanged(HistoryContentType type, String content, ClipboardSource? source) async {
    _onChangeLock.synchronized(
      () => _onChanged(type, content, source).catchError(
        (err, stack) {
          Log.warn(tag, "onChanged $err, $stack");
        },
      ),
    );
  }

  Future<void> _onChanged(HistoryContentType type, String content, ClipboardSource? source) async {
    if (appConfig.innerCopy) {
      appConfig.innerCopy = false;
      return;
    }
    //和上次复制的内容相同
    if (last?.type == type.value && last?.content == content) {
      return;
    }
    int size = content.length;
    switch (type) {
      case HistoryContentType.text:
        //文本无特殊实现，此处留空
        break;
      case HistoryContentType.image:
        //如果上次也是复制的图片/文件，判断其md5与本次比较，若相同则跳过
        if (last?.type == HistoryContentType.image.value) {
          var md51 = await File(last!.content).md5;
          var md52 = await File(content).md5;
          //两次的图片存在且相同，跳过。
          if (md51 == md52 && md51 != null) {
            return;
          }
        }
        //移动到设置的路径然后删除临时文件
        var tempFile = File(content);
        size = await tempFile.length();
        var newPath = "${Platform.isAndroid ? appConfig.androidPrivatePicturesPath : appConfig.fileStorePath}/${tempFile.fileName}";
        var newFile = File(newPath);
        FileUtil.moveFile(content, newPath);
        content = newFile.normalizePath;
        break;
      case HistoryContentType.richText:
        break;
      case HistoryContentType.file:
        break;
      case HistoryContentType.sms:
        //判断是否符合短信同步规则，符合则继续，否则终止
        var rules = jsonDecode(
          appConfig.smsRules,
        )["data"] as List<dynamic>;
        var hasMatch = false;
        for (var rule in rules) {
          if (content.matchRegExp(rule["rule"])) {
            hasMatch = true;
            break;
          }
        }
        //规则列表不为空且未匹配成功，忽略
        if (rules.isNotEmpty && !hasMatch) {
          return;
        }
        break;
      default:
        throw Exception("UnSupport Type: ${type.label}-${type.value}");
    }
    var history = History(
      id: appConfig.snowflake.nextId(),
      uid: appConfig.userId,
      devId: appConfig.devInfo.guid,
      time: DateTime.now().toString(),
      content: content,
      type: type.value,
      size: size,
      source: source?.id,
    );
    if (source != null && appConfig.sourceRecord) {
      await sourceService.addOrUpdate(
        AppInfo(
          id: appConfig.snowflake.nextId(),
          appId: source.id,
          devId: appConfig.device.guid,
          name: source.name,
          iconB64: source.iconB64!,
        ),
        true,
      );
    }
    await addData(history, true);
  }

  @override
  Future<void> onSync(MessageData msg) async {
    var send = msg.send;
    final syncData = msg.data["data"];
    Map<dynamic, dynamic> data = {};
    if (syncData is String) {
      data = jsonDecode(msg.data["data"]);
    } else {
      data = syncData;
    }
    msg.data["data"] = "";
    var opRecord = OperationRecord.fromJson(msg.data);
    final historyMap = data.cast<String, dynamic>();
    dynamic historyContent = historyMap["content"];
    if (historyContent is Map) {
      historyMap["content"] = "";
    }
    History history = History.fromJson(historyMap);
    history.sync = true;
    if (opRecord.module == Module.historyTop) {
      //发送同步确认
      sktService.sendData(send, MsgType.ackSync, {
        "id": opRecord.id,
        "hisId": history.id,
        "module": Module.historyTop.moduleName,
      });
      //更新数据库
      return dbService.historyDao.setTop(history.id, history.top).then((v) {
        //更新页面
        updateData(
          (h) => h.id == history.id,
          (his) => his.top = history.top,
        );
      });
    }
    Future f = Future.value();
    if ([OpMethod.add, OpMethod.update].contains(opRecord.method)) {
      switch (HistoryContentType.parse(history.type)) {
        case HistoryContentType.image:
          var fileName = historyContent["fileName"];
          var data = historyContent["data"].cast<int>();
          var path = "${appConfig.fileStorePath}/$fileName";
          if (appConfig.saveToPictures) {
            path = "${Constants.androidPicturesPath}/${Constants.appName}/$fileName";
            Log.debug(tag, "newPath $path");
          }
          history.content = path;
          //如果没有权限则请求
          if (!(await PermissionHelper.testAndroidStoragePerm())) {
            await PermissionHelper.reqAndroidStoragePerm();
          }
          var file = File(path);
          if (!file.existsSync()) {
            file.writeAsBytesSync(data);
            if (appConfig.saveToPictures) {
              androidChannelService.notifyMediaScan(path);
            }
          }
          break;
        default:
          break;
      }
    }
    switch (opRecord.method) {
      case OpMethod.add:
        f = addData(history, false);
        //不是缺失数据的同步时放入本地剪贴板，如果是缺失数据但是需要豁免的也放行
        if (msg.key != MsgType.missingData || _missingDataCopyMsg == history.id) {
          appConfig.innerCopy = true;
          var type = ClipboardContentType.parse(history.type);
          if (type != ClipboardContentType.image) {
            clipboardManager.copy(type, history.content);
          } else if (appConfig.autoCopyImageAfterSync) {
            clipboardManager.copy(type, history.content);
          }
          if (_missingDataCopyMsg == history.id) {
            _missingDataCopyMsg = null;
          }
        }
        break;
      case OpMethod.delete:
        f = dbService.historyDao.delete(history.id).then((cnt) {
          if (cnt == null || cnt == 0) return 0;
          _tempList.removeWhere((element) => element.data.id == history.id);
          debounceUpdate();
          return cnt;
        });
        break;
      case OpMethod.update:
        f = dbService.historyDao.updateHistory(history).then((cnt) {
          if (cnt == 0) return 0;
          var i = _tempList.indexWhere((element) => element.data.id == history.id);
          if (i == -1) return cnt;
          _tempList[i] = ClipData(history);
          debounceUpdate();
          return cnt;
        });
        break;
      default:
        return;
    }
    f.then((cnt) {
      if (cnt == null && cnt <= 0) return;
      //将同步过来的数据添加到本地操作记录
      dbService.opRecordDao.add(opRecord.copyWith(history.id.toString()));
    });
    notifyHistoryWindow();
    return f.whenComplete(() {
      //发送同步确认
      sktService.sendData(send, MsgType.ackSync, {
        "id": opRecord.id,
        "hisId": history.id,
        "module": Module.history.moduleName,
      });
    });
  }

  ///添加页面和数据库数据
  Future<int> addData(History history, bool shouldSync) async {
    var clip = ClipData(history);
    final contentType = HistoryContentType.parse(history.type);
    var cnt = await dbService.historyDao.add(clip.data);
    if (cnt <= 0) return cnt;
    notifyHistoryWindow();
    _tempList.add(clip);
    debounceUpdate();
    if (!shouldSync) return cnt;
    //添加历史操作记录
    var opRecord = OperationRecord.fromSimple(
      Module.history,
      OpMethod.add,
      history.id.toString(),
    );
    dbService.opRecordDao.addAndNotify(opRecord);

    //region update source on Android
    if (Platform.isAndroid && shouldSync && appConfig.sourceRecordViaDumpsys) {
      var start = DateTime.now();
      clipboardManager.getLatestWriteClipboardSource().then((source) async {
        Log.debug(tag, "source $source");
        if (source == null) return;
        //一般获取时间不会超过2s，超过该时间视为无效
        final isTimeout = source.isTimeout(2000);
        Log.debug(tag, "source time: ${source.time?.toString()}, timeout: $isTimeout");
        var end = DateTime.now();
        Log.debug(tag, "source: ${source.name}, offset: ${end.difference(start).inMilliseconds}");
        if (isTimeout) {
          return;
        }
        const offset = Duration(milliseconds: 500);
        final historyCreateTime = DateTime.parse(history.time);
        //如果获取的最新的剪贴板时间不在指定的误差时间，则跳过 todo 考虑提供设置项自行设置
        if (!(source.time?.isWithinRange(offset, historyCreateTime) ?? false)) {
          Log.debug(tag, "latest write clipboard source not in range(${offset.inMilliseconds}ms) time: ${source.time}, id: ${source.id}");
          return;
        }

        history.source = source.id;
        // add source icon
        sourceService.addOrUpdate(
          AppInfo(
            id: appConfig.snowflake.nextId(),
            appId: source.id,
            devId: appConfig.device.guid,
            name: source.name,
            iconB64: source.iconB64!,
          ),
          true,
        );
        final cnt = await dbService.historyDao.updateHistorySource(history.id, source.id);
        if ((cnt ?? 0) > 0) {
          //更新剪贴板来源
          //先将之前的剪贴板来源操作记录删除再添加操作记录
          await dbService.opRecordDao.deleteHistorySourceRecords(history.id, Module.historySource.moduleName);
          dbService.opRecordDao.addAndNotify(
            OperationRecord.fromSimple(
              Module.historySource,
              OpMethod.update,
              history.id.toString(),
            ),
          );
        }
      });
    }
    //endregion

    switch (contentType) {
      case HistoryContentType.text:
        var rules = jsonDecode(appConfig.tagRules)["data"];
        for (var rule in rules) {
          if (history.content.matchRegExp(rule["rule"])) {
            //添加标签
            var tag = HistoryTag(
              rule["name"],
              history.id,
            );
            tagService.add(tag);
          }
        }
        break;
      case HistoryContentType.sms:
        //添加标签
        tagService.add(
          HistoryTag(
            TranslationKey.sms.tr,
            history.id,
          ),
        );
        break;
      default:
    }
    return cnt;
  }

//endregion
}
