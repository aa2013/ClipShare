import 'dart:async';
import 'dart:convert';

import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/listeners/history_data_listener.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
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

  bool get listening => _listening;

  AndroidNotificationListenerService();

  void startListening() {
    _listen?.cancel();
    _listening = false;
    _listen = NotificationListenerService.notificationsStream.listen((event) async {
      try {
        if (event.hasRemoved == true) {
          Log.debug(tag, "notification removed ${event.content}");
          return;
        }
        var map = <String, String?>{};
        final hasImg = event.haveExtraPicture ?? false;
        map["title"] = event.title;
        map["content"] = event.content;
        if(hasImg){
          try{
            map["img"] = base64Encode(event.extrasPicture!);
          }catch(err,stack){
            Log.debug(tag, "$err, $stack");
          }
        }
        final pkgName = event.packageName!;
        var appInfo = _sourceService.getAppInfoByAppId(pkgName);
        final missing = appInfo == null;
        appInfo = _sourceService.getAppInfoByAppId(pkgName);
        var source = ClipboardSource(
          id: pkgName,
          name: appInfo?.name ?? "",
          time: null,
          iconB64: appInfo?.iconB64 ?? "",
        );
        if (missing && appInfo != null) {
          _sourceService.addOrUpdate(appInfo, true);
        }
        HistoryDataListener.inst.onChanged(HistoryContentType.notification, jsonEncode(map), source);
      } catch (err, stack) {
        Log.error(tag, "error: $err, stack:$stack");
      }
    });
    _listening = true;
  }

  void stopListening() {
    _listen?.cancel();
    _listen = null;
    _listening = false;
  }

  @override
  void onClose() {
    super.onClose();
    _listen?.cancel();
    _listen = null;
  }
}
