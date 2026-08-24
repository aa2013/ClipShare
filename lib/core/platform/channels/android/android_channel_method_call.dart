part of 'android_channel_provider.dart';

Future<void> _onMethodCall(Ref ref, MethodCall call) async {
  var method = AndroidChannelMethod.values.byName(call.method);
  switch (method) {
    case AndroidChannelMethod.onScreenOpened:
    case AndroidChannelMethod.onScreenUnlocked:
    case AndroidChannelMethod.onScreenClosed:
      //todo
      // ScreenOpenedListener.inst.notify(method);
      break;
    case AndroidChannelMethod.onFileOpened:
      final uri = call.arguments['uri']?.toString();
      if (uri.isBlank == true) {
        logger.debug(AndroidChannelNotifier.tag, 'ignore empty uri');
        break;
      }
      await _handleIncomingUri(uri!);
      break;
    case AndroidChannelMethod.onNotifyClick:
      // 通知点击由原生通过 notifyId 回传，统一交给 NotifyUtil 分发处理。
      final notifyId = call.arguments['notifyId'];
      if (notifyId is num) {
        final notifier = ref.read(notifyProvider.notifier);
        await notifier.handleNotifyClick(notifyId.toInt());
      }
      break;
    case AndroidChannelMethod.onSmsChanged:
      final content = call.arguments['content']!;
      final recorder = ref.read(historyRecorderProvider.notifier);
      recorder.add(
        RawHistoryEvent(
          history: simpleHistory(ref, HistoryContentType.sms, content),
          sync: true,
          source: null,
        ),
      );
      break;
    default:
  }
  return Future(() => false);
}

/// 统一处理以 Uri 形式进入应用的外部文件，并复用现有文件信息解析能力。
Future<void> _handleIncomingUri(String uri) async {
  final fileInfo = await uriFileReader.getFileInfoFromUri(uri);
  if (fileInfo == null) {
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      snackbar.warn(context, TranslationKey.failedToLoad.tr);
    }
    logger.debug(AndroidChannelNotifier.tag, '未从uri中获取到文件名称和大小：uri = $uri');
    return;
  }
  final fileName = fileInfo.fileName;
  final size = fileInfo.size;
  logger.info(AndroidChannelNotifier.tag, 'ShareMedia fileName $fileName, size $size');
  await _handleIncomingDropItems([DropItemFileUri(uri, fileName, size)]);
}

/// 统一处理直接可落地为本地路径的外部文件集合。
Future<void> _handleIncomingDropItems(List<DropItem> files) async {
  logger.debug(AndroidChannelNotifier.tag, files);
  if (files.isEmpty) {
    return;
  }
  //todo
  // gotoOnlineDevicesPage(files);
}
