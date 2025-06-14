import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:clipshare/app/widgets/memory_image_with_not_found.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class AppIcon extends StatefulWidget {
  final String appId;
  final void Function()? onDeleteClicked;

  const AppIcon({
    super.key,
    required this.appId,
    this.onDeleteClicked,
  });

  @override
  State<AppIcon> createState() => _AppIconState();
}

class _AppIconState extends State<AppIcon> {
  final multiWindowService = Get.find<MultiWindowChannelService>();
  Widget? appIconImage;

  Key? appIconImageKey;

  AppInfo? appInfo;
  static const iconSize = 20.0;
  static var caches = <String, AppInfo>{};

  AppInfo? getAppInfoByAppId(String appId) {
    try {
      final sourceService = Get.find<ClipboardSourceService>();
      return sourceService.getAppInfoByAppId(appId);
    } catch (_) {
      if (caches.containsKey(appId)) {
        return caches[appId];
      }
      multiWindowService.getAllSources(0).then((list) {
        caches.clear();
        for (var item in list) {
          caches[item.appId] = item;
        }
      });
      return null;
    }
  }

  Widget get notFoundIcon {
    return Tooltip(
      message: TranslationKey.appIconLoadError.trParams({
        "appName": appInfo?.name ?? widget.appId,
      }),
      child: const Icon(
        Icons.error_outline,
        color: Colors.orange,
        size: iconSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.appId;
    final appInfo = getAppInfoByAppId(source);
    if (appInfo == null) return notFoundIcon;
    if (appInfo.iconB64 == this.appInfo?.iconB64 && appIconImage != null) {
      return appIconImage!;
    }
    this.appInfo = appInfo;
    appIconImageKey = Key(appInfo.iconB64);
    final image = MemImageWithNotFound(
      bytes: appInfo.iconBytes,
      notFoundIcon: notFoundIcon,
      width: iconSize,
      height: iconSize,
    );
    if (widget.onDeleteClicked != null) {
      return RoundedChip(
        label: Text(TranslationKey.source.tr),
        avatar: image,
        deleteIcon: const Icon(Icons.clear),
        onDeleted: widget.onDeleteClicked,
      );
    } else {
      appIconImage = Tooltip(
        message: appInfo.name,
        child: image,
      );
    }
    return appIconImage!;
  }
}
