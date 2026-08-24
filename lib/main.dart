import 'dart:async';

import 'package:clipshare/app.dart';
import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/shared/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main(List<String> args) async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      if (isDesktop) {
        await windowManager.ensureInitialized();
      }
      //todo 多窗口标记占位：启动参数 args.firstOrNull == 'multi_window' 时走子窗口流程
      runApp(const ProviderScope(child: ClipShareApp()));
    },
    (err, stack) {
      // 全局异常捕获
      logger.error('global-error', err, stack);
    },
  );
}
