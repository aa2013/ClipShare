import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/history_dao.dart';
import 'package:clipshare/core/database/dao/operation_record_dao.dart';
import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare/core/database/tables/operation_record.dart';
import 'package:clipshare/core/extensions/file_extension.dart';
import 'package:clipshare/core/providers/device/local_device_info.dart';
import 'package:clipshare/core/providers/local_device/local_device_info_provider.dart';
import 'package:clipshare/core/providers/settings/app_paths/app_paths_provider.dart';
import 'package:clipshare/core/providers/settings/clipboard/clipboard_settings.dart';
import 'package:clipshare/core/providers/settings/clipboard/clipboard_settings_provider.dart';
import 'package:clipshare/core/providers/settings/forward/forward_settings_provider.dart';
import 'package:clipshare/core/providers/settings/notification/notification_settings_provider.dart';
import 'package:clipshare/core/providers/snowflake/id_provider.dart';
import 'package:clipshare/core/utils/file_util.dart';
import 'package:clipshare/core/utils/snowflake.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/extensions/time_extension.dart';
import 'package:clipshare/shared/models/module.dart';
import 'package:clipshare/shared/models/op_method.dart';
import 'package:clipshare/shared/models/rule/rule_apply_result.dart';
import 'package:clipshare/shared/models/rule/rule_exec_result.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:clipshare_clipboard_listener/models/clipboard_source.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'history_event.dart';

part 'history_recorder_provider.g.dart';

@Riverpod(keepAlive: true)
class HistoryRecorderNotifier extends _$HistoryRecorderNotifier {
  static const tag = 'HistoryRecorderNotifier';
  final _controller = StreamController<HistoryDeltaEvent>.broadcast();
  final _rawEvents = StreamController<RawHistoryEvent>.broadcast();

  ClipboardSettings get _clipboardSettings => ref.read(clipboardSettingsProvider).requireValue;

  Snowflake get _idGenerator => ref.read(idProvider);

  BaseDeviceInfo get _self => ref.read(localDeviceInfoProvider).requireValue.baseDeviceInfo;

  HistoryDao get _historyDao => ref.read(appDbProvider).requireValue.historyDao;

  OperationRecordDao get _opRecordDao => ref.read(appDbProvider).requireValue.operationRecordDao;

  /// 下游订阅此 Stream 获取已处理的事件
  Stream<HistoryDeltaEvent> get events => _controller.stream;
  History? _latest;

  History? get latest => _latest;

  @override
  Future<void> build() async {
    final db = await ref.read(appDbProvider.future);
    _latest = await db.historyDao.getLatestLocalClip();
    unawaited(_listen());
    ref.onDispose(_controller.close);
    ref.onDispose(_rawEvents.close);
  }

  Future<void> add(RawHistoryEvent event) async {
    _rawEvents.add(event);
  }

  Future<void> _listen() async{
    await for(var rawEvent in _rawEvents.stream){
      try {
        await _process(rawEvent);
      } catch (err, stack) {
        logger.error(tag, err, stack);
      }
    }
  }

  ///处理原始事件，入库去重等
  Future<void> _process(RawHistoryEvent event) async {
    History? history = event.history;
    var content = history.content;
    //空内容
    if (content.isEmpty) {
      return;
    }
    //和上次复制的内容相同
    if (_latest?.type == history.type && _latest?.content == content) {
      return;
    }
    history = await _preProcess(history);
    if (history == null) {
      return;
    }

    final (historyResult, ruleResult) = await _applyRules(history);
    history = historyResult;
    if (history == null) {
      return;
    }
    history = await _processSource(history, event.source);
    //处理数据库
    final deltaEvent = await _addData(history, ruleResult, event.sync);
    if (deltaEvent == null) {
      return;
    }
    _latest = deltaEvent.history;
    _controller.add(deltaEvent);
  }

  ///预处理
  Future<History?> _preProcess(History history) async {
    var content = history.content;
    final type = HistoryContentType.parse(history.type);
    int size = content.length;
    switch (type) {
      case HistoryContentType.text:
        if (_checkExceedMaxLength(size)) {
          return null;
        }
        break;
      case HistoryContentType.image:
        //如果上次也是复制的图片/文件，判断其md5与本次比较，若相同则跳过
        if (_latest?.type == HistoryContentType.image.value) {
          var md51 = await File(_latest!.content).md5;
          var md52 = await File(content).md5;
          //两次的图片存在且相同，跳过。
          if (md51 == md52 && md51 != null) {
            return null;
          }
        }
        final appPaths = ref.read(appPathsProvider).requireValue;
        //移动到设置的路径然后删除临时文件
        var tempFile = File(content);
        size = await tempFile.length();
        var newPath = '${isAndroid ? appPaths.androidPrivatePicturesPath : appPaths.screenShotStorePath}/${tempFile.fileName}';
        var newFile = File(newPath);
        //todo 如果开启了自定义图片保存以及截图复制，是否会导致冲突？
        FileUtil.moveFile(content, newPath);
        content = newFile.normalizePath;
        history = history.copyWith(content: content);
        break;
      case HistoryContentType.notification:
        final notificationSettings = ref.read(notificationSettingsProvider).requireValue;
        if (!notificationSettings.enableRecordNotification) {
          logger.warn(tag, 'Not allow to record notification');
          return null;
        }
        break;
      default:
    }
    return history;
  }

  ///应用规则
  Future<(History?, RuleApplyResult?)> _applyRules(History history) async {
    final type = HistoryContentType.parse(history.type);
    var content = history.content;
    //todo
    // var applyResult = await ruleController.apply(type, content, source);
    final applyResult = RuleExecResult.success(RuleApplyResult(content: content, tags: {}, isSyncDisabled: false, isFinalRule: false));
    if (applyResult.result?.isDropped ?? false) {
      //截取最大长度
      final logContent = '${content.substringMinLen(0, 20)}...';
      //丢弃
      logger.info(tag, 'content: $logContent，dropped');
      return (null, null);
    }
    final extracted = applyResult.result?.extractedContent;
    if (extracted.isNotNullAndEmpty) {
      //提取内容不为空，尝试复制
      await clipboardManager.copy(ClipboardContentType.text, extracted!);
    }
    switch (type) {
      case HistoryContentType.image:
        content = applyResult.result?.content ?? content;
        break;
      case HistoryContentType.notification:
        content = jsonEncode({
          'title': applyResult.result?.title ?? TranslationKey.unknown.tr,
          'content': applyResult.result?.content ?? TranslationKey.unknown.tr,
        });
        break;
      default:
    }
    if (history.content == content) {
      return (history, applyResult.result);
    }
    return (
      history.copyWith(content: content),
      applyResult.result,
    );
  }

  ///处理剪贴板来源
  Future<History> _processSource(History history, ClipboardSource? source) async {
    final type = HistoryContentType.parse(history.type);
    if (_clipboardSettings.sourceRecord || type == HistoryContentType.notification) {
      if (source != null) {
        //todo
        // await sourceService.addOrUpdate(
        //   AppInfo(
        //     id: _idGenerator.nextId(),
        //     appId: source.id,
        //     devId:_self.id,
        //     name: source.name,
        //     iconB64: source.iconB64 ?? '',
        //   ),
        //   true,
        // );
      }
    } else {
      if (history.source != null) {
        history = history.copyWith(source: const Value(null));
      }
    }
    return history;
  }

  ///添加数据库数据
  Future<HistoryDeltaEvent?> _addData(History history, RuleApplyResult? applyResult, bool shouldSync, [bool notify = true]) async {
    final contentType = HistoryContentType.parse(history.type);
    if (_clipboardSettings.sendBroadcastOnAdd) {
      // todo
      // final devService = Get.find<DeviceService>();
      // androidChannelService.sendHistoryChangedBroadcast(contentType, history.content, history.devId, devService.getName(history.devId));
    }
    var cnt = await _historyDao.add(history);
    if (cnt <= 0) {
      return null;
    }
    //todo
    // notifyHistoryWindow();
    if (!shouldSync) {
      final source = history.source;
      //todo
      // final appInfo = sourceService.getAppInfoByAppId(source);
      // //若同步的数据有来源信息但是本地未缓存，则请求同步该来源信息
      // if (source != null && appInfo == null) {
      //   DataSender.sendDataByDevId(
      //     history.devId,
      //     MsgType.reqAppInfo,
      //     {"appId": source},
      //   );
      // }
      return HistoryDeltaEvent(history: history, operation: OpMethod.add);
    }
    //添加历史操作记录
    var opRecord = newOperationRecord(
      _idGenerator,
      _self,
      Module.history,
      OpMethod.add,
      history.id.toString(),
    );
    final syncDisabled = applyResult?.isSyncDisabled ?? false;
    if(syncDisabled){
      await _opRecordDao.add(opRecord);
      return HistoryDeltaEvent(history: history, operation: OpMethod.add);
    }
    // 不发送通知
    if(!notify){
      return HistoryDeltaEvent(history: history, operation: OpMethod.add);
    }
    //允许同步且通知
    await _opRecordDao.addAndNotify(opRecord);
    final forwardSettings = await ref.read(forwardSettingsProvider.future);
    //若启用存储同步, 检查是否同步成功
    if (forwardSettings.enableStorageSync) {
      final record = await _opRecordDao.getById(opRecord.id);
      if (record != null && record.storageSync == true) {
        await _historyDao.setSync(history.id, true);
        history = history.copyWith(sync: true);
      }
    }

    //region update source on Android
    if (isAndroid && shouldSync && _clipboardSettings.sourceRecordViaDumpsys) {
      var start = DateTime.now();
      unawaited(
          clipboardManager.getLatestWriteClipboardSource().then((source) async {
            logger.debug(tag, 'source $source');
            if (source == null) return;
            //一般获取时间不会超过2s，超过该时间视为无效
            final isTimeout = source.isTimeout(2000);
            logger.debug(tag, 'source time: ${source.time?.toString()}, timeout: $isTimeout');
            var end = DateTime.now();
            logger.debug(tag, 'source: ${source.name}, offset: ${end.difference(start).inMilliseconds}');
            if (isTimeout) {
              return;
            }
            final offset = 500.ms;
            final historyCreateTime = DateTime.parse(history.time);
            //如果获取的最新的剪贴板时间不在指定的误差时间，则跳过 todo 考虑提供设置项自行设置
            if (!(source.time?.isWithinRange(offset, historyCreateTime) ??
                false)) {
              logger.debug(tag, 'latest write clipboard source not in range(${offset.inMilliseconds}ms) time: ${source.time}, id: ${source.id}');
              return;
            }
            //更新来源
            history = history.copyWith(source: Value(source.id));
            // add source icon
            // todo
            // sourceService.addOrUpdate(
            //   AppInfo(
            //     id: appConfig.snowflake.nextId(),
            //     appId: source.id,
            //     devId: appConfig.device.guid,
            //     name: source.name,
            //     iconB64: source.iconB64!,
            //   ),
            //   true,
            // );
            await _historyDao.updateHistorySourceAndNotify(
              history.id,
              source.id,
              _idGenerator,
              _self,
            );
            final event = HistoryDeltaEvent(history: history, operation: OpMethod.update);
            _controller.add(event);
          })
      );
    }
    //endregion
    final tags = <String>{};
    tags.addAll(applyResult?.tags ?? {});
    switch (contentType) {
      case HistoryContentType.sms:
        tags.add(TranslationKey.sms.tr);
        break;
      case HistoryContentType.notification:
        tags.add(TranslationKey.notification.tr);
        break;
      default:
    }
    if (tags.isNotEmpty) {
      for (var tag in tags) {
        // todo
        // tagService.add(HistoryTag(tag, history.id));
      }
    }
    return HistoryDeltaEvent(history: history, operation: OpMethod.add);
  }

  ///检查是否超出最大长度
  bool _checkExceedMaxLength(int n) {
    final maxLength = _clipboardSettings.recordMaxLength;
    //超出设定大小则忽略
    if (maxLength > 0 && n > maxLength) {
      logger.warn(tag, 'Record length $n > RecordMaxLength($maxLength)');
      return true;
    }
    return false;
  }
}
