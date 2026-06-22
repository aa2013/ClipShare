import 'dart:async';
import 'dart:convert';

import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/listeners/history_data_listener.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare_clipboard_listener/models/clipboard_source.dart';
import 'package:get/get.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

class AndroidNotificationListenerService extends GetxService {
  static const tag = "AndroidNotificationListenerService";
  StreamSubscription<ServiceNotificationEvent>? _listen;
  final _sourceService = Get.find<ClipboardSourceService>();
  var _listening = false;
  final _notifyHashSet = <String>{};

  bool get listening => _listening;

  AndroidNotificationListenerService();

  void startListening() {
    logger.info(tag, "start listening");
    _listen?.cancel();
    _listening = false;
    _listen = NotificationListenerService.notificationsStream.listen(_onNotifyEvent);
    _listening = true;
  }

  void stopListening() {
    logger.info(tag, "stop listening");
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
      final hash = "$pkg$title$content".toMd5();
      if (!_notifyHashSet.add(hash)) {
        //duplicate content
        return;
      }
      Future.delayed(2.s, () => _notifyHashSet.remove(hash));
      var map = <String, String?>{};
      final hasImg = event.haveExtraPicture ?? false;

      map["pkg"] = pkg;
      map["title"] = title;
      map["content"] = content;

      if (hasImg) {
        try {
          map["img"] = base64Encode(event.extrasPicture!);
        } catch (err, stack) {
          logger.debug(tag, "$err, $stack");
        }
      }
      final pkgName = event.packageName!;
      await _sourceService.loadFuture;
      final appInfo = _sourceService.getAppInfoByAppId(pkgName);
      ClipboardSource? source;
      if (appInfo != null) {
        _sourceService.addOrUpdate(appInfo, true);
        source = ClipboardSource(
          id: pkgName,
          name: appInfo.name,
          time: null,
          iconB64: appInfo.iconB64,
        );
      } else {
        logger.warn(tag, "not found notification source info");
      }
      HistoryDataListener.inst.onChanged(HistoryContentType.notification, jsonEncode(map), source);
    } catch (err, stack) {
      logger.error(tag, "error: $err, stack:$stack");
    }
  }

  @override
  void onClose() {
    super.onClose();
    _listen?.cancel();
    _listen = null;
  }
}
