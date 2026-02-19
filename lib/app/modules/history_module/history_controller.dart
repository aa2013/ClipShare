import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:clipshare/app/data/enums/white_black_mode.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/handlers/sync/abstract_data_sender.dart';
import 'package:clipshare/app/listeners/screen_opened_listener.dart';
import 'package:clipshare/app/listeners/sync_listener.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/utils/extensions/device_extension.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:path/path.dart' as p;
import 'package:clipshare/app/utils/notify_util.dart';
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
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:synchronized/synchronized.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class HistoryController extends GetxController with WidgetsBindingObserver implements HistoryDataObserver, SyncListener, ScreenOpenedObserver {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final sktService = Get.find<SocketService>();
  final multiWindowChannelService = Get.find<MultiWindowChannelService>();
  final androidChannelService = Get.find<AndroidChannelService>();
  final clipChannelService = Get.find<ClipChannelService>();
  final sourceService = Get.find<ClipboardSourceService>();
  final tagService = Get.find<TagService>();
  final devService = Get.find<DeviceService>();

  //region 属性
  final String tag = "HistoryController";

  var _exporting = false;
  bool get exporting => _exporting;
  var _cancelExporting = false;
  bool get cancelExporting => _cancelExporting;

  ///不要直接操作这个list，请操作 _tempList 并执行 debounceUpdate() 方法以进行防抖更新
  final list = List<ClipData>.empty(growable: true).obs;

  ///需要更新并复制的最新的数据 id
  int? _missingDataCopyMsg;

  ///onChange事件锁
  final _onChangeLock = Lock();

  ///获取最新的一条数据，如果 tmpList 和 list 都有数据就判断时间，否则返回不为空的
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

  bool _screenUnlocked = true;

  //熄屏后的数据同步
  History? _syncDataOnScreenOff;

  //防止短时间内频繁刷新ui的临时缓冲列表
  final List<ClipData> _tempList = List.empty(growable: true);

  //endregion

  //region 生命周期
  @override
  void onInit() {
    super.onInit();
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
    ScreenOpenedListener.inst.register(this);
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
    ScreenOpenedListener.inst.remove(this);
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
  void setMissingDataCopyMsg(Map<String, dynamic> opRecord, [bool fromStorage = false]) {
    final syncData = opRecord["data"];
    Map<dynamic, dynamic> data = {};
    if (syncData is String) {
      data = jsonDecode(syncData);
    } else {
      data = syncData;
    }
    final history = History.fromJson(data.cast<String, dynamic>());
    //比本地的记录旧，跳过
    if (last != null && history.id < last!.id) {
      return;
    }
    if (fromStorage) {
      var type = ClipboardContentType.parse(history.type);
      var copy = false;
      if (type != ClipboardContentType.image) {
        copy = true;
        clipboardManager.copy(type, history.content);
      } else if (appConfig.autoCopyImageAfterSync) {
        copy = true;
        clipboardManager.copy(type, history.content);
      }
      if (_screenUnlocked == false && copy) {
        _syncDataOnScreenOff = history;
      }
    } else {
      _missingDataCopyMsg = history.id;
    }
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
    //和上次复制的内容相同
    if (last?.type == type.value && last?.content == content) {
      return;
    }
    int size = content.length;
    final matchResult = appConfig.matchesContentBlacklist(type, content, source);
    if (matchResult.matched) {
      Log.info(tag, "match blacklist, rule = ${matchResult.rule}, content $content");
      return;
    }
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
            iconB64: source.iconB64 ?? "",
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
            const maxTimeoutMs = 10000;
            if (offsetMs <= maxTimeoutMs) {
              try {
                final json = jsonDecode(history.content);
                final pkgName = json["pkg"];
                final appInfo = sourceService.getAppInfoByAppId(pkgName);
                Uri? iconUri;
                if (appInfo != null) {
                  final documentsPath = await Constants.documentsPath;
                  final file = File(p.join(documentsPath, "appIcons", "${appInfo.appId}.png"));
                  await file.parent.create(recursive: true);
                  await file.writeAsBytes(appInfo.iconBytes);
                  iconUri = file.uri;
                }
                final notificationTitle = json["title"];
                final notificationContent = json["content"];
                const notifyKey = "showMobileNotify";
                final notifyId = await NotifyUtil.notify(
                  title: notificationTitle,
                  content: notificationContent,
                  key: notifyKey,
                  notificationLogoUri: iconUri,
                );
                if (notifyId != null) {
                  Future.delayed(2.s, () {
                    NotifyUtil.cancel(notifyKey, notifyId);
                  });
                }
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
          var clip = ClipData(history);
          var copy = false;
          if(clip.isText || clip.isImage){
            final type = ClipboardContentType.parse(history.type);
            if (clip.isText) {
              copy = true;
              clipboardManager.copy(type, history.content);
            } else if (clip.isImage && appConfig.autoCopyImageAfterSync) {
              copy = true;
              clipboardManager.copy(type, history.content);
            }
            if (_screenUnlocked == false && copy) {
              _syncDataOnScreenOff = history;
            }
            if (_missingDataCopyMsg == history.id) {
              _missingDataCopyMsg = null;
            }
          }else{
            break;
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
    final cnt = await _process2Db(history, opRecord.method, msg.key == MsgType.missingData, true);
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
    final cnt = await _process2Db(history, opRecord.method, loadingMissingData, false);
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
    if (appConfig.sendBroadcastOnAdd) {
      final devService = Get.find<DeviceService>();
      androidChannelService.sendHistoryChangedBroadcast(contentType, history.content, history.devId, devService.getName(history.devId));
    }
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

  @override
  void onScreenOpened() {}

  @override
  void onScreenUnlocked() {
    Log.debug(tag, "屏幕解锁");
    _screenUnlocked = true;
    if (_syncDataOnScreenOff != null) {
      //已启用复制熄屏时的最新数据
      if (appConfig.reCopyOnScreenUnlocked) {
        //复制熄屏时的数据
        var type = ClipboardContentType.parse(_syncDataOnScreenOff!.type);
        var content = _syncDataOnScreenOff!.content;
        clipboardManager.copy(type, content);
      }
      _syncDataOnScreenOff = null;
    }
  }

  @override
  void onScreenClosed() {
    _screenUnlocked = false;
  }

  //endregion

  //region 导出
  void export(FutureOr<List<History>> Function(int lastId) loadDataFunc) {
    var loadingController = LoadingProgressController();
    Global.showTipsDialog(
      context: Get.context!,
      text: TranslationKey.historyOutputTips.tr,
      onOk: () {
        Global.showLoadingDialog(
          context: Get.context!,
          loadingText: TranslationKey.exporting.tr,
          showCancel: true,
          controller: loadingController,
          onCancel: () {
            _cancelExporting = true;
            _exporting = false;
          },
        );
        export2Excel(loadingController, loadDataFunc).then((result) {
          //关闭进度动画
          Get.back();
          //手动取消
          if (!exporting) {
            return;
          }
          if (result) {
            Global.showSnackBarSuc(context: Get.context!, text: TranslationKey.outputSuccess.tr);
          } else {
            Global.showSnackBarWarn(context: Get.context!, text: TranslationKey.outputFailed.tr);
          }
        })
            .catchError((err, stack) {
          //关闭进度动画
          Get.back();
          Global.showTipsDialog(
            context: Get.context!,
            title: TranslationKey.outputFailed.tr,
            text: "$err. $stack",
          );
        })
            .whenComplete(() {
          //更新状态
          _exporting = false;
          _cancelExporting = false;
        });
      },
      showCancel: true,
    );
  }

  ///导出为 excel
  Future<bool> export2Excel(LoadingProgressController loadingController, FutureOr<List<History>> Function(int lastId) loadDataFunc) async {
    if (exporting) return false;
    _exporting = true;
    int lastId = 0;
    //第一行是标题头，内容从第二行开始
    int rowNum = 2;
    var histories = List<History>.empty(growable: true);
    while (true) {
      if (cancelExporting) {
        return false;
      }
      var list = await loadDataFunc(lastId);
      if (list.isEmpty) {
        break;
      }
      histories.addAll(list);
      lastId = list.last.id;
    }
    histories.sort((a, b) {
      // 首先按 top 排序（true 在前，false 在后）
      if (a.top != b.top) {
        return a.top ? -1 : 1; // true 在前，所以返回 -1
      }
      // 如果 top 相同，则按 id 降序排列
      return b.id.compareTo(a.id); // 降序：b.id - a.id
    });
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    _addExcelHeader(sheet);
    final Style dateTimeStyle = workbook.styles.add('CustomDateTimeStyle');
    dateTimeStyle.numberFormat = 'yyyy-MM-dd HH:mm:ss';
    dateTimeStyle.vAlign = VAlignType.center;
    final Style vAlign = workbook.styles.add('verticalCenter');
    vAlign.vAlign = VAlignType.center;

    var lastTime = DateTime.now();
    loadingController.update(0, histories.length);

    for (var i = 0; i < histories.length; i++) {
      var item = histories[i];
      if (cancelExporting) {
        return false;
      }
      //转换为excel数据(对于内容超过32767字符的会合并单元格，统计使用了多少行)
      final useRows = await _add2ExcelSheet(sheet, item, rowNum, dateTimeStyle, vAlign);
      rowNum += useRows;
      var now = DateTime.now();
      if (now.difference(lastTime).inMilliseconds.abs() > 10) {
        loadingController.update(i + 1);
      }
      lastTime = now;

      if (ClipData(item).isImage) {
        await Future.delayed(50.ms);
      }
    }
    loadingController.update(histories.length);
    Log.debug(tag, "add2ExcelSheet finished");
    final List<int> bytes = workbook.saveAsStream();
    Log.debug(tag, "workbook bytes: ${bytes.length}(${bytes.length.sizeStr})");
    await FileUtil.exportFileBytes(
      TranslationKey.export2Excel.tr,
      TranslationKey.export2ExcelFileName.tr,
      Uint8List.fromList(bytes),
    );
    workbook.dispose();
    return true;
  }

  ///添加导出excel的头（第一行）
  void _addExcelHeader(Worksheet sheet) {
    sheet.getRangeByName("A1").setText("时间");
    sheet.setColumnWidthInPixels(1, 150);
    sheet.getRangeByName("B1").setText("类型");
    sheet.getRangeByName("C1").setText("设备");
    sheet.getRangeByName("D1").setText("来源");
    sheet.getRangeByName("E1").setText("是否置顶");
    sheet.getRangeByName("F1").setText("内容");
    sheet.setColumnWidthInPixels(6, 570);
    sheet.getRangeByName("G1").setText("内容长度");
  }

  ///将历史数据添加到excel对象中，返回值为使用的行数
  Future<int> _add2ExcelSheet(Worksheet sheet, History history, int rowNum, Style timeStyle, Style vAlignStyle) async {
    if (rowNum <= 0) {
      throw ArgumentError("rowNum cannot less than 0");
    }
    final clip = ClipData(history);
    final time = DateTime.parse(history.time);
    final type = HistoryContentType.parse(history.type);
    if (type == HistoryContentType.file) {
      //文件同步跳过
      return 0;
    }
    late final String content;
    const maxCellLength = 32767;
    if(type == HistoryContentType.notification){
      content = ClipData(history).notificationContent ?? "[❌ Parse Data Failed]";
    }else{
      //转换 unicode 控制字符 \u0000 ~ \u001f，这些字符会导致 excel 打开失败
      //需要替换为 _x0000_ 这样的
      content = history.content.replaceAllMapped(
        RegExp(r'[\x00-\x1F]'),
            (match) => '_x${match.group(0)!.codeUnitAt(0).toRadixString(16).padLeft(4, '0')}_',
      );
    }
    var rowsOffset = 0;
    if (content.length > maxCellLength) {
      //单个单元格最多支持32767字符，否则会导致excel打开失败
      rowsOffset = (content.length / maxCellLength).ceil() - 1;
    }
    final devName = devService.getName(history.devId);
    final size = clip.sizeText;
    sheet.getRangeByName("A$rowNum:A${rowNum + rowsOffset}")
      ..merge()
      ..cellStyle = timeStyle
      ..setDateTime(time);
    sheet.getRangeByName("B$rowNum:B${rowNum + rowsOffset}")
      ..merge()
      ..cellStyle = vAlignStyle
      ..setText(type.label);
    sheet.getRangeByName("C$rowNum:C${rowNum + rowsOffset}")
      ..merge()
      ..cellStyle = vAlignStyle
      ..setText(devName);
    final sourceService = Get.find<ClipboardSourceService>();
    var source = "";
    if (history.source != null) {
      final app = sourceService.getAppInfoByAppId(history.source!);
      if (app != null) {
        source = app.name;
      }
    }
    sheet.getRangeByName("D$rowNum:D${rowNum + rowsOffset}")
      ..merge()
      ..cellStyle = vAlignStyle
      ..setText(source);
    sheet.getRangeByName("E$rowNum:E${rowNum + rowsOffset}")
      ..merge()
      ..cellStyle = vAlignStyle
      ..setNumber(history.top ? 1 : 0);
    if (clip.isImage) {
      final file = File(history.content);
      final cell = sheet.getRangeByName("F$rowNum");
      sheet.setRowHeightInPixels(rowNum, 100);
      final rowHeight = cell.rowHeight;
      final cellWidth = cell.columnWidth;
      if (file.existsSync()) {
        final List<int> bytes = await file.readAsBytes();
        //only supports png and jpeg
        final picture = sheet.pictures.addStream(rowNum, 5, bytes);
        //rowHeight取出来是单位pt，转为像素需要 * 1.33
        picture.height = min(rowHeight * 1.33, 100).toInt(); // 限制高度
        picture.width = min(cellWidth * 1.33, 200).toInt(); // 限制宽度
      }
    } else {
      for (var i = 0; i <= rowsOffset; i++) {
        final start = i * maxCellLength;
        final end = min((i + 1) * maxCellLength, content.length);
        sheet.getRangeByName("F${rowNum + i}").setText(content.substring(start, end));
      }
    }
    sheet.getRangeByName("G$rowNum:G${rowNum + rowsOffset}")
      ..merge()
      ..cellStyle = vAlignStyle
      ..setText(size);
    return rowsOffset + 1;
  }

//endregion

}
