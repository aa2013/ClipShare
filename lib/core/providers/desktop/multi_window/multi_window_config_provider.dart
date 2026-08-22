import 'dart:async';

import 'package:clipshare/core/providers/desktop/multi_window/multi_window_args_provider.dart';
import 'package:clipshare/core/providers/desktop/multi_window/multi_window_config_state.dart';
import 'package:clipshare/core/providers/desktop/multi_window/multi_window_dispatch.dart';
import 'package:clipshare/core/utils/log.dart';
import 'package:clipshare/shared/enums/multi_window_config.dart';
import 'package:clipshare/shared/enums/multi_window_method.dart';
import 'package:clipshare/shared/models/desktop_multi_window_args.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'multi_window_config_provider.g.dart';

/// 子窗口配置：启动参数初始化，并监听主窗口 [MultiWindowMethod.updateConfig] 推送。
@Riverpod(keepAlive: true)
class MultiWindowConfigNotifier extends _$MultiWindowConfigNotifier
    implements MultiWindowMessageListener {
  static const _tag = 'MultiWindowConfigNotifier';

  @override
  MultiWindowConfigState build() {
    final args = ref.watch(multiWindowArgsProvider);
    if (args == null) {
      return const MultiWindowConfigState();
    }
    multiWindowMsgDispatchService.addListener(this);
    ref.onDispose(() {
      multiWindowMsgDispatchService.removeListener(this);
    });
    return _stateFromArgs(args);
  }

  /// 用启动参数构造初始配置。
  MultiWindowConfigState _stateFromArgs(DesktopMultiWindowArgs args) {
    return MultiWindowConfigState(
      enabled: true,
      locale: Locale(args.languageCode, args.countryCode),
      themeMode: args.themeMode,
      autoClosePopupOnBlur: args.autoClosePopupOnBlur,
      clickToPaste: args.otherArgs[MultiWindowConfig.clickToPaste.name] as bool? ?? false,
    );
  }

  @override
  FutureOr<void> onMultiWindowMessage(
    MultiWindowMethod method,
    Map<String, dynamic> args,
    int fromWindowId,
  ) async {
    if (method != MultiWindowMethod.updateConfig) {
      return;
    }
    final allConfigs = MultiWindowConfig.values.map((c) => c.name).toList(growable: false);
    final configKeys = args.keys.where(allConfigs.contains).map(MultiWindowConfig.values.byName);
    for (final key in configKeys) {
      try {
        final value = args[key.name];
        switch (key) {
          case MultiWindowConfig.language:
            if (value is! Map) {
              logger.warn(_tag, 'language expects Map, got ${value.runtimeType}');
              break;
            }
            _onLanguageChanged(
              value.map((key, val) => MapEntry(key.toString(), val)),
            );
            break;
          case MultiWindowConfig.themeMode:
            if (value is! String) {
              logger.warn(_tag, 'themeMode expects String, got ${value.runtimeType}');
              break;
            }
            _onThemeModeChanged(value);
            break;
          case MultiWindowConfig.autoClosePopupOnBlur:
            if (value is! bool) {
              logger.warn(_tag, 'autoClosePopupOnBlur expects bool, got ${value.runtimeType}');
              break;
            }
            _onAutoClosePopupOnBlurChanged(value);
            break;
          case MultiWindowConfig.clickToPaste:
            if (value is! bool) {
              logger.warn(_tag, 'clickToPaste expects bool, got ${value.runtimeType}');
              break;
            }
            _onClickToPasteChanged(value);
            break;
        }
      } catch (err, stack) {
        logger.error(_tag, err, stack);
      }
    }
  }

  void _onLanguageChanged(Map<String, dynamic> value) {
    final languageCode = value['languageCode'];
    if (languageCode is! String || languageCode.isEmpty) {
      logger.warn(_tag, 'language missing languageCode');
      return;
    }
    final locale = Locale(languageCode, value['countryCode'] as String?);
    state = state.copyWith(locale: locale);
  }

  void _onThemeModeChanged(String value) {
    try {
      state = state.copyWith(themeMode: ThemeMode.values.byName(value));
    } catch (err, stack) {
      logger.error(_tag, err, stack);
    }
  }

  /// 同步主窗口的弹窗失焦关闭偏好；关闭该偏好时清除固定状态由窗体侧自行处理。
  void _onAutoClosePopupOnBlurChanged(bool value) {
    state = state.copyWith(autoClosePopupOnBlur: value);
  }

  /// 同步主窗口的单击粘贴偏好。
  void _onClickToPasteChanged(bool value) {
    state = state.copyWith(clickToPaste: value);
  }
}
