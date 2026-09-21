import 'dart:async';
import 'dart:convert';

import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare/core/services/clipboard/clipboard_source_provider.dart';
import 'package:clipshare/core/services/history/history_event.dart';
import 'package:clipshare/core/services/history/history_recorder_provider.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare_clipboard_listener/models/clipboard_source.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'android_notification_listener_provider.g.dart';

@Riverpod(keepAlive: true)
class AndroidNotificationListenerNotifier extends _$AndroidNotificationListenerNotifier {
  static const tag = 'AndroidNotificationListenerService';
  StreamSubscription<ServiceNotificationEvent>? _listen;
  var _listening = false;
  static final _notifyHashSet = <String>{};

  bool get listening => _listening;

  @override
  void build() {
    ref.onDispose(stopListening);
  }

  void startListening() {
    logger.info(tag, 'start listening');
    _listen?.cancel();
    _listening = false;
    _listen = NotificationListenerService.notificationsStream.listen(_onNotifyEvent);
    _listening = true;
  }

  void stopListening() {
    logger.info(tag, 'stop listening');
    _listen?.cancel();
    _listen = null;
    _listening = false;
  }

  Future<void> _onNotifyEvent(ServiceNotificationEvent event) async {
    try {
      if (event.hasRemoved == true) {
        return;
      }
      final pkg = event.packageName;
      final title = event.title;
      final content = event.content;
      if (content?.isNullOrEmpty ?? true) {
        return;
      }
      final hash = '$pkg$title$content'.toMd5();
      if (!_notifyHashSet.add(hash)) {
        //duplicate content
        return;
      }
      Future.delayed(2.s, () => _notifyHashSet.remove(hash));
      var map = <String, String?>{};
      final hasImg = event.haveExtraPicture ?? false;

      map['pkg'] = pkg;
      map['title'] = title;
      map['content'] = content;

      if (hasImg) {
        try {
          map['img'] = base64Encode(event.extrasPicture!);
        } catch (err, stack) {
          logger.debug(tag, '$err, $stack');
        }
      }
      final pkgName = event.packageName!;
      final sourceState = await ref.read(clipboardSourceProvider.future);
      final appInfo = sourceState.getAppInfoByAppId(pkgName);
      ClipboardSource? source;
      if (appInfo != null) {
        final notifier = ref.read(clipboardSourceProvider.notifier);
        await notifier.addOrUpdate(appInfo, true);
        source = ClipboardSource(
          id: pkgName,
          name: appInfo.name,
          time: null,
          iconB64: appInfo.iconB64,
        );
      } else {
        logger.warn(tag, 'not found notification source info');
      }
      final recorder = ref.read(historyRecorderProvider.notifier);
      recorder.add(
        RawHistoryEvent(
          history: simpleHistory(ref, HistoryContentType.notification, jsonEncode(map)),
          sync: true,
          source: source,
        ),
      );
    } catch (err, stack) {
      logger.error(tag, 'error: $err, stack:$stack');
    }
  }
}
