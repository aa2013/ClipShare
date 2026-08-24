import 'package:clipshare/core/clipboard/clipboard_source_provider.dart';
import 'package:clipshare/core/database/tables/app_info.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/widgets/base/rounded_chip.dart';
import 'package:clipshare/shared/widgets/memory_image_with_not_found.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppIcon extends ConsumerStatefulWidget {
  final String appId;
  final double? iconSize;
  final void Function()? onDeleteClicked;

  const AppIcon({
    super.key,
    required this.appId,
    this.onDeleteClicked,
    this.iconSize,
  });

  @override
  ConsumerState<AppIcon> createState() => _AppIconState();
}

class _AppIconState extends ConsumerState<AppIcon> {
  Widget? appIconImage;
  Key? appIconImageKey;
  AppInfo? appInfo;
  static const iconSize = 20.0;

  AppInfo? getAppInfoByAppId(String appId) {
    // 从剪贴板来源缓存读取：先命中来源库，回退本机已安装应用
    return ref
        .watch(clipboardSourceProvider)
        .value
        ?.getAppInfoByAppId(appId);
  }

  Widget get notFoundIcon {
    return Tooltip(
      message: TranslationKey.appIconLoadError.trParams({
        'appName': appInfo?.name ?? widget.appId,
      }),
      child: Icon(
        Icons.error_outline,
        color: Colors.orange,
        size: widget.iconSize ?? iconSize,
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
      key: appIconImageKey,
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
