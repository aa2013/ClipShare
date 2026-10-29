import 'dart:io';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// 更新日志页：渲染随包分发的当前平台 Markdown 更新日志
class UpdateLogPage extends StatelessWidget {
  const UpdateLogPage({super.key});

  /// 更新日志资产路径前缀。
  static const updateLogAssetPrefix = 'assets/md/updateLogs-';

  /// 资产路径中的平台名：IOS/MacOS 保持资产文件名的大小写，其余平台首字母大写。
  static String get platformName {
    if (isIOS) {
      return 'IOS';
    }
    if (isMacOS) {
      return 'MacOS';
    }
    //windows -> Windows, linux -> Linux
    return Platform.operatingSystem.upperFirst;
  }

  @override
  Widget build(BuildContext context) {
    final showAppBar = context.isCompactScreen;
    final content = FutureBuilder(
      future: rootBundle.loadString('$updateLogAssetPrefix$platformName.md'),
      builder: (context, v) {
        return Markdown(
          data: v.data ?? TranslationKey.failedToReadUpdateLog.tr,
          selectable: true,
        );
      },
    );
    if (showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: Text(TranslationKey.updateLogPageAppBarTitle.tr),
        ),
        body: SafeArea(child: content),
      );
    }
    return Card(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      margin: const EdgeInsets.all(8),
      child: content,
    );
  }
}
