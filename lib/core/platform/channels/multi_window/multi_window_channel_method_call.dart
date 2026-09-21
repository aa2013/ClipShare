part of 'multi_window_channel_provider.dart';

/// 复制/粘贴串行链：平台通道 handler 不排队，并发 copy 会交错执行
/// （写A→写B→粘→粘 会把 B 粘两次）；用 Future 链保证一次只处理一条。
Future<void> _copyChain = Future.value();

Future _onMethodCall(MultiWindowChannelNotifier self, Ref ref, MethodCall call, int fromWindowId) async {
  final historyDao = ref.read(appDbProvider).requireValue.historyDao;
  final deviceDao = ref.read(appDbProvider).requireValue.deviceDao;
  final historyTagDao = ref.read(appDbProvider).requireValue.historyTagDao;
  final opRecordDao = ref.read(appDbProvider).requireValue.operationRecordDao;
  final localDevice = ref.read(localDeviceInfoProvider).requireValue;
  final devState = ref.read(deviceProvider).requireValue;
  final sourceService = ref.read(clipboardSourceProvider).requireValue;
  final preference = await ref.read(preferenceSettingsProvider.future);
  var args = jsonDecode(call.arguments);
  var method = MultiWindowMethod.values.byName(call.method);
  switch (method) {
    case MultiWindowMethod.getHistories:
      int fromId = args['fromId'];
      final filter = SearchFilter.fromJson(args['filter']);
      final lst = await historyDao.getHistoriesPageByFilter(
        filter,
        fromId != 0,
        max(fromId, 0),
      );
      var devMap = devState.toIdNameMap();
      //todo
      // devMap[localDevice.baseDeviceInfo.id] = appConfig.device.displayName;
      var res = {
        'list': lst,
        'devInfos': devMap,
      };
      return jsonEncode(res);
    case MultiWindowMethod.getAllDevices:
      //加载所有设备
      final devices = await deviceDao.getAllDevices();
      //todo
      // return jsonEncode([appConfig.device, ...devices]);
      break;
    case MultiWindowMethod.getAllTagNames:
      //加载所有标签名
      final tagNames = await historyTagDao.getAllTagNames();
      return jsonEncode(tagNames);
    case MultiWindowMethod.getAllSources:
      //加载所有设备信息
      return jsonEncode(sourceService.appInfos);
    case MultiWindowMethod.copy:
      final id = args['id'];
      // 串行化：并发 copy 时剪贴板写/粘贴会交错（见 _copyChain 注释），
      // 链条上的 catchError 保证单条失败不阻塞后续条目。
      _copyChain = _copyChain.then((_) => _doCopyAndPaste(ref, id)).catchError((err, stack) {
        logger.error(MultiWindowChannelNotifier.tag, err, stack);
      });
      await _copyChain;
      break;
    case MultiWindowMethod.copyContent:
      final content = args['content'];
      // copyContent 也写系统剪贴板，须与 copy 同链串行——否则并发时合并内容的
      // 写入会插进 copy 的写/粘之间，粘出去的是合并内容而非用户点的条目。
      _copyChain = _copyChain.then((_) => clipboardManager.copy(ClipboardContentType.text, content)).catchError((err, stack) {
        logger.error(MultiWindowChannelNotifier.tag, err, stack);
        return false;
      });
      await _copyChain;
      break;
    case MultiWindowMethod.getCompatibleOnlineDevices:
      //todo
      var devices = [];
      // var devices = devController.compatibleOnlineDevices;
      logger.info(MultiWindowChannelNotifier.tag, 'devices $devices');
      return jsonEncode(devices);
    case MultiWindowMethod.syncFiles:
      final paths = (args['files'] as List<dynamic>).cast<String>();
      final items = paths.map((path) => DropItemFile(path)).toList(growable: false);
      final files = [];
      //todo
      // final files = await pendingFileService.resolvePendingItems(items);
      var devices = List<Device>.empty(growable: true);
      for (var devMap in (args['devices'] as List<dynamic>)) {
        devices.add(Device.fromJson(devMap));
      }
      logger.info(MultiWindowChannelNotifier.tag, 'files $paths');
      logger.info(MultiWindowChannelNotifier.tag, 'devIds $devices');
      //todo
      // FileSyncHandler.sendFiles(
      //   devices: devices,
      //   files: files,
      //   context: Get.context!,
      // );
      break;
    case MultiWindowMethod.storeWindowPos:
      var pos = args['pos'].toString();
      if (preference.recordHistoryDialogPosition) {
        final configDao = ref.read(appDbProvider).requireValue.configDao;
        await configDao.addOrUpdate(ConfigKey.historyDialogPosition, pos);
        ref.invalidate(preferenceSettingsProvider);
      }
      break;
    case MultiWindowMethod.closeWindow:
      var windowId = args['closeWindowId'] as int;
      //IPC 载荷带 MultiWindowChannelNotifier.tag：仅 history 需要关闭点击外部监听（devices 不触碰，避免互相踩）
      var tag = MultiWindowTag.getValue(args['MultiWindowChannelNotifier.tag'] as String);
      self.addHideWindow(windowId, tag);
      break;
    case MultiWindowMethod.updateWindowSize:
      //判断是否记录窗体大小，并记录
      if (!preference.rememberPopupWindowSize) {
        break;
      }
      final type = WindowType.parse(args['type']);
      final [width, height] = (args['size'] as String).split('x').map((item) => item.toDouble()).toList();
      final size = Size(width, height);
      await _updatePopupWindowSize(ref, type, size);
      break;
    case MultiWindowMethod.updateHistoryTop:
      final id = args['id'] as int;
      final isTop = args['isTop'] as bool;
      final cnt = await historyDao.setTop(id, isTop);
      if (cnt == null || cnt <= 0) return;
      final recorder = ref.read(historyRecorderProvider.notifier);
      final history = await historyDao.getById(id);
      if (history == null) {
        return false;
      }
      recorder.addDelta(
        HistoryDeltaEvent(
          history: history,
          operation: OpMethod.update,
        ),
      );
      var opRecord = newOperationRecord(
        ref.read(idProvider),
        localDevice.baseDeviceInfo,
        Module.historyTop,
        OpMethod.update,
        id,
      );
      await opRecordDao.addAndNotify(opRecord);
      break;
    case MultiWindowMethod.deleteHistory:
      final id = args['id'] as int;
      final history = await historyDao.getById(id);
      if (history == null) {
        return false;
      }
      await historyDao.deleteByCascade(id);
      final recorder = ref.read(historyRecorderProvider.notifier);
      recorder.addDelta(
        HistoryDeltaEvent(
          history: history,
          operation: OpMethod.delete,
        ),
      );
      //添加删除记录
      var opRecord = newOperationRecord(
        ref.read(idProvider),
        localDevice.baseDeviceInfo,
        Module.historyTop,
        OpMethod.update,
        id,
      );
      //通知其他设备
      await opRecordDao.addAndNotify(opRecord);
      break;
    case MultiWindowMethod.setHistoryPinned:
      //子窗口置顶状态同步（运行期，不持久化）：置顶时点击外部不自动关闭弹窗
      //todo
      // appConfig.historyPinned.value = args["pinned"] == true;
      break;
    default:
  }
  //都不符合，返回空
  return Future.value();
}

///执行复制并粘贴到上一个窗口（由 copy 消息经 _copyChain 串行调用）。
///等待复制并粘贴完成后再返回，确保弹窗在粘贴完成之前不会提前隐藏，避免粘贴目标窗口错乱。
Future<void> _doCopyAndPaste(Ref ref, dynamic id) async {
  final historyDao = ref.read(appDbProvider).requireValue.historyDao;
  final history = await historyDao.getById(id);
  if (history != null) {
    await history.copyContent();
    var result = await clipboardManager.pasteToPreviousWindow();
    if (result != PasteResult.success) {
      final notifier = ref.read(notifyProvider.notifier);
      await notifier.notify(content: result.tr, key: 'paste2Window');
    }
  }
}

///更新弹窗大小
Future<void> _updatePopupWindowSize(Ref ref, WindowType type, Size size) async {
  if (!isWindows) {
    return;
  }
  final configDao = ref.read(appDbProvider).requireValue.configDao;
  late final ConfigKey key;
  switch (type) {
    case WindowType.history:
      key = ConfigKey.historyWindowSize;
      break;
    case WindowType.fileSender:
      key = ConfigKey.fileSenderWindowSize;
      break;
    default:
      return;
  }
  await configDao.addOrUpdate(key, '${size.width.toStringAsFixed(2)}x${size.height.toStringAsFixed(2)}');
  ref.invalidate(preferenceSettingsProvider);
}
