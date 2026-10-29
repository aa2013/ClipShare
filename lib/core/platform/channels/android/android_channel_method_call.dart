part of 'android_channel_provider.dart';

Future<void> _onMethodCall(AndroidChannelNotifier notifier, Ref ref, MethodCall call) async {
  var method = AndroidChannelMethod.values.byName(call.method);
  switch (method) {
    case .onScreenOpened:
      notifier._screenEvents.add(const ScreenOpenedEvent());
      break;
    case .onScreenUnlocked:
      notifier._screenEvents.add(const ScreenUnlockedEvent());
      break;
    case .onScreenClosed:
      notifier._screenEvents.add(const ScreenClosedEvent());
      break;
    case .onFileOpened:
      final uri = call.arguments['uri']?.toString();
      if (uri.isBlank == true) {
        logger.debug(AndroidChannelNotifier.tag, 'ignore empty uri');
        break;
      }
      final receiver = ref.read(androidExternalFileReceiveProvider.notifier);
      await receiver.handleIncomingUri(uri!);
      break;
    case .onNotifyClick:
      // 通知点击由原生通过 notifyId 回传，统一分发处理。
      final notifyId = call.arguments['notifyId'];
      if (notifyId is num) {
        final notifier = ref.read(notifyProvider.notifier);
        await notifier.handleNotifyClick(notifyId.toInt());
      }
      break;
    case .onSmsChanged:
      final content = call.arguments['content']!;
      final recorder = ref.read(historyRecorderProvider.notifier);
      recorder.emitRaw(
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
