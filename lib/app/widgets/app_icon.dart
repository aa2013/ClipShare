import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/repository/entity/tables/app_info.dart';
import 'package:clipshare/app/services/clipboard_source_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class AppIcon extends StatefulWidget {
  final String appId;

  const AppIcon({
    super.key,
    required this.appId,
  });

  @override
  State<AppIcon> createState() => _AppIconState();
}

class _AppIconState extends State<AppIcon> {
  Widget? appIconImage;

  Key? appIconImageKey;

  AppInfo? appInfo;
  final sourceService = Get.find<ClipboardSourceService>();
  static const iconSize = 20.0;

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
    final appInfo = sourceService.getAppInfoByAppId(source);
    if (appInfo == null) return notFoundIcon;
    if (appInfo.iconB64 == this.appInfo?.iconB64 && appIconImage != null) {
      return appIconImage!;
    }
    this.appInfo = appInfo;
    appIconImageKey = Key(appInfo.iconB64);
    appIconImage = Tooltip(
      message: appInfo.name,
      child: Image.memory(
        appInfo.iconBytes,
        key: appIconImageKey,
        width: iconSize,
        height: iconSize,
        errorBuilder: (context, Object error, StackTrace? stackTrace) {
          return notFoundIcon;
        },
      ),
    );
    return appIconImage!;
  }
}
