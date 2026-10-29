import 'dart:async';

import 'package:clipshare/app.dart';
import 'package:clipshare/core/constants/app_constants.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/settings/app_paths/custom_path_resolver.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:clipshare/shared/utils/windows_injector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main(List<String> args) async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      if (isDesktop) {
        await windowManager.ensureInitialized();
        if (isWindows) {
          //解决 windows 下 win + v 无法写入到输入框的问题
          WindowsInjector.instance.injectKeyData();
        }
      }
      isMultiWindow = args.firstOrNull == 'multi_window';
      //todo 多窗口标记占位：启动参数 args.firstOrNull == 'multi_window' 时走子窗口流程
      //路径配置必须先于 runApp 完成，启动期的 appDb/appPaths 会同步读取该全局配置
      await initCustomPathConfig();
      runApp(const ProviderScope(child: ClipShareApp()));
    },
    (err, stack) {
      // 全局异常捕获
      logger.error('global-error', err, stack);
    },
  );
}
