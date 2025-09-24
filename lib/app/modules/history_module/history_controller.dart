import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/enums/white_black_mode.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/handlers/sync/abstract_data_sender.dart';
import 'package:clipshare/app/listeners/sync_listener.dart';
import 'package:clipshare/app/utils/extensions/device_extension.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:clipshare_clipboard_listener/models/clipboard_source.dart';
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
import 'package:clipshare/app/services/transport/socket_service.dart';
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
      DataSender.addSyncListener(Module.history, this);
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
    DataSender.removeSyncListener(Module.history, this);
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
    _debounce = Timer(200.ms, () {
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
        final matchResult = appConfig.matchesContentBlacklist(type, content, source);
        if (matchResult.matched) {
          Log.info(tag, "match blacklist, rule = ${matchResult.rule}, content $content");
          return;
        }
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
        var newPath = "${Platform.isAndroid ? appConfig.androidPrivatePicturesPath : appConfig.screenShotStorePath}/${tempFile.fileName}";
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
        var rules = jsonDecode(appConfig.smsRules)["data"] as List<dynamic>;
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
      case HistoryContentType.notification:
        if (!appConfig.enableRecordNotification) {
          Log.warn(tag, "Not allow to record notification");
          return;
        }
        final matchResult = appConfig.matchesNotificationRuleList(content, source!.id);
        final isBlacklistMode = appConfig.currentNotificationWhiteBlackMode == WhiteBlackMode.black;
        //匹配到黑名单，结束
        if (matchResult.matched && isBlacklistMode) {
          Log.info(tag, "match blacklist, rule = ${matchResult.rule}, content $content");
          return;
        }
        //白名单模式，但未匹配到，结束
        if (!isBlacklistMode && !matchResult.matched) {
          Log.info(tag, "not matched whitelist, content $content");
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
    if (appConfig.sourceRecord || type == HistoryContentType.notification) {
      if (source != null) {
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
    } else {
      history.source = null;
    }
    await addData(history, true);
  }

  ///抽取历史数据的map，因为有可能是 map，后续需要反序列化为操作记录
  Map<dynamic, dynamic> _extractHistoryData(dynamic data) {
    Map<dynamic, dynamic> syncData = {};
    if (syncData is String) {
      syncData = jsonDecode(data);
    } else {
      syncData = data;
    }
    return syncData;
  }

  ///抽取内容（如果是文件，内容是一个 map）
  dynamic _extractHistoryContent(Map<String, dynamic> historyMap) {
    dynamic historyContent = historyMap["content"];
    if (historyContent is Map) {
      historyMap["content"] = "";
    }
    return historyContent;
  }

  ///更新置顶状态
  Future<void> _updateHistoryTop(History history) {
    return dbService.historyDao.setTop(history.id, history.top).then((v) {
      //更新页面
      updateData(
        (h) => h.id == history.id,
        (his) => his.top = history.top,
      );
    });
  }

  Future<void> _processData(History history, dynamic historyContent, OpMethod method, DevInfo sender) async {
    if ([OpMethod.add, OpMethod.update].contains(method)) {
      switch (HistoryContentType.parse(history.type)) {
        case HistoryContentType.image:
          var fileName = historyContent["fileName"];
          var data = historyContent["data"].cast<int>();
          var path = "${appConfig.fileStorePath}/$fileName";
          if (Platform.isAndroid) {
            if (appConfig.saveToPictures) {
              path = "${Constants.androidPicturesPath}/${Constants.appName}/$fileName";
            } else {
              path = "${appConfig.androidPrivatePicturesPath}/$fileName";
            }
            Log.debug(tag, "newPath $path");
          }
          history.content = path;
          //如果没有权限则请求
          if (!(await PermissionHelper.testAndroidStoragePerm())) {
            await PermissionHelper.reqAndroidStoragePerm();
          }
          var file = File(path);
          await file.parent.create(recursive: true);
          if (!file.existsSync()) {
            file.writeAsBytesSync(data);
            if (appConfig.saveToPictures) {
              androidChannelService.notifyMediaScan(path);
            }
          }
          break;
        case HistoryContentType.notification:
          if (appConfig.enableShowMobileNotification) {
            final now = DateTime.now();
            final hisTime = DateTime.parse(history.time);
            final offsetMs = now.difference(hisTime).inMilliseconds.abs();
            Log.info(tag, "show mobile notification, time offset ${offsetMs}ms");
            const maxTimeoutMs = 2000;
            if (offsetMs <= maxTimeoutMs) {
              try {
                final json = jsonDecode(history.content);
                final notificationContent = json["content"];
                Global.notify(
                  title: TranslationKey.notificationFromDevice.trParams({"devName": sender.name}),
                  content: notificationContent,
                );
              } catch (err, stack) {
                Log.error(tag, "show mobile notification error: $err, $stack");
              }
            } else {
              Log.debug(tag, "The sync notification is outdated (${offsetMs}ms exceeds ${maxTimeoutMs}ms), skipping.");
            }
          }
          break;
        default:
          break;
      }
    }
  }

  Future<int> _process2Db(History history, OpMethod method, bool loadingMissingData, bool notify) async {
    var cnt = 0;
    switch (method) {
      case OpMethod.add:
        cnt = await addData(history, false, notify);
        //不是缺失数据的同步时放入本地剪贴板，如果是缺失数据但是需要豁免的也放行
        if (!loadingMissingData || _missingDataCopyMsg == history.id) {
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
        cnt = await dbService.historyDao.delete(history.id).then((cnt) {
          if (cnt == null || cnt == 0) return 0;
          sourceService.removeNotUsed();
          _tempList.removeWhere((element) => element.data.id == history.id);
          debounceUpdate();
          return cnt;
        });
        break;
      case OpMethod.update:
        cnt = await dbService.historyDao.updateHistory(history).then((cnt) {
          if (cnt == 0) return 0;
          var i = _tempList.indexWhere((element) => element.data.id == history.id);
          if (i == -1) return cnt;
          _tempList[i] = ClipData(history);
          debounceUpdate();
          return cnt;
        });
        break;
      default:
    }
    return cnt;
  }

  @override
  Future<void> onSync(MessageData msg) async {
    var sender = msg.send;
    //抽取历史记录的map内容，然后将data赋值为空（操作记录反序列化里面data是字符串）
    final historyMap = _extractHistoryData(msg.data["data"]).cast<String, dynamic>();
    msg.data["data"] = "";

    var opRecord = OperationRecord.fromJson(msg.data);

    //处理历史记录内容，如果该记录是文件，content字段里面是一个map需要做转换
    dynamic historyContent = _extractHistoryContent(historyMap);

    //反序列化为对象
    History history = History.fromJson(historyMap);
    history.sync = true;
    if (opRecord.module == Module.historyTop) {
      //发送同步确认
      sender.sendData(MsgType.ackSync, {
        "id": opRecord.id,
        "hisId": history.id,
        "module": Module.historyTop.moduleName,
      });
      //更新数据库
      return _updateHistoryTop(history);
    }

    await _processData(history, historyContent, opRecord.method, msg.send);
    final cnt = await _process2Db(history, opRecord.method, msg.key != MsgType.missingData, true);
    if (cnt <= 0) return;
    notifyHistoryWindow();
    //将同步过来的数据添加到本地操作记录
    dbService.opRecordDao.add(opRecord.copyWith(data: history.id.toString()));
    //发送同步确认
    await sender.sendData(MsgType.ackSync, {
      "id": opRecord.id,
      "hisId": history.id,
      "module": Module.history.moduleName,
    });
  }

  @override
  Future<void> onStorageSync(Map<String, dynamic> map, Device sender, bool loadingMissingData) async {
    //抽取历史记录的map内容，然后将data赋值为空（操作记录反序列化里面data是字符串）
    final historyMap = _extractHistoryData(map["data"]).cast<String, dynamic>();
    map["data"] = "";

    var opRecord = OperationRecord.fromJson(map);

    //处理历史记录内容，如果该记录是文件，content字段里面是一个map需要做转换
    dynamic historyContent = _extractHistoryContent(historyMap);

    //反序列化为对象
    History history = History.fromJson(historyMap);
    history.sync = true;
    if (opRecord.module == Module.historyTop) {
      //更新数据库
      return _updateHistoryTop(history);
    }

    await _processData(history, historyContent, opRecord.method, DevInfo.fromDevice(sender));
    final cnt = await _process2Db(history, opRecord.method, !loadingMissingData, false);
    if (cnt <= 0) return;
    notifyHistoryWindow();
    //将同步过来的数据添加到本地操作记录
    await dbService.opRecordDao.add(
      opRecord.copyWith(
        data: history.id.toString(),
        storageSync: true,
      ),
    );
  }

  ///添加页面和数据库数据
  Future<int> addData(History history, bool shouldSync, [bool notify = true]) async {
    var clip = ClipData(history);
    final contentType = HistoryContentType.parse(history.type);
    var cnt = await dbService.historyDao.add(clip.data);
    if (cnt <= 0) return cnt;
    notifyHistoryWindow();
    _tempList.add(clip);
    debounceUpdate();
    if (!shouldSync) {
      final source = history.source;
      final appInfo = sourceService.getAppInfoByAppId(source);
      //若同步的数据有来源信息但是本地未缓存，则请求同步该来源信息
      if (source != null && appInfo == null) {
        DataSender.sendDataByDevId(
          history.devId,
          MsgType.reqAppInfo,
          {"appId": source},
        );
      }
      return cnt;
    }
    //添加历史操作记录
    var opRecord = OperationRecord.fromSimple(
      Module.history,
      OpMethod.add,
      history.id.toString(),
    );
    if (notify) {
      await dbService.opRecordDao.addAndNotify(opRecord);
      //若启用存储同步检查是否同步成功
      if (appConfig.enableStorageSync) {
        final record = await dbService.opRecordDao.getById(opRecord.id);
        if (record != null && record.storageSync == true) {
          await dbService.historyDao.setSync(history.id, true).then((_) {
            for (var clip in _tempList) {
              if (clip.data.id.toString() == history.id.toString()) {
                clip.data.sync = true;
                debounceUpdate();
                break;
              }
            }
          });
        }
      }
    } else {
      await dbService.opRecordDao.add(opRecord);
    }

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
        final offset = 500.ms;
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
        await dbService.historyDao.updateHistorySourceAndNotify(history.id, source.id);
      });
    }
    //endregion

    switch (contentType) {
      case HistoryContentType.text:
        var rules = jsonDecode(appConfig.tagRules)["data"];
        for (var rule in rules) {
          if (history.content.matchRegExp(rule["rule"])) {
            //添加标签
            var tag = HistoryTag(rule["name"], history.id);
            tagService.add(tag);
          }
        }
        break;
      case HistoryContentType.sms:
        //添加标签
        tagService.add(HistoryTag(TranslationKey.sms.tr, history.id));
        break;
      case HistoryContentType.notification:
        //添加通知标签
        tagService.add(HistoryTag(TranslationKey.notification.tr, history.id));
        break;
      default:
    }
    return cnt;
  }

  //endregion
}
