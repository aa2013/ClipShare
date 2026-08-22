import 'dart:async';
import 'dart:convert';

import 'package:clipshare/core/constants/platform_constants.dart';
import 'package:clipshare/core/utils/log.dart';
import 'package:clipshare/shared/enums/multi_window_method.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';

/// 跨窗口消息监听接口
abstract class MultiWindowMessageListener {
  FutureOr<void> onMultiWindowMessage(
    MultiWindowMethod method,
    Map<String, dynamic> args,
    int fromWindowId,
  );
}

/// 桌面多窗口 MethodChannel 消息分发
class MultiWindowDispatchService {
  static const _tag = 'MultiWindowDispatchService';
  static MultiWindowDispatchService? _instance;

  final Set<MultiWindowMessageListener> _listeners = {};
  bool _handlerRegistered = false;

  MultiWindowDispatchService._private();

  /// 获取进程内分发器；不会在首次 get 时注册 MethodHandler。
  static MultiWindowDispatchService get instance {
    return _instance ??= MultiWindowDispatchService._private();
  }

  /// 注册跨窗口消息监听；桌面端首次注册时才挂 MethodHandler。
  void addListener(MultiWindowMessageListener listener) {
    _listeners.add(listener);
    _ensureMethodHandler();
  }

  /// 移除跨窗口消息监听。
  void removeListener(MultiWindowMessageListener listener) {
    _listeners.remove(listener);
  }

  /// 注册 Handler
  void _ensureMethodHandler() {
    if (!isDesktop || _handlerRegistered) {
      return;
    }
    _handlerRegistered = true;
    DesktopMultiWindow.setMethodHandler((MethodCall call, int fromWindowId) async {
      try {
        final args = _parseArguments(call.arguments);
        final method = MultiWindowMethod.values.byName(call.method);
        for (final listener in List<MultiWindowMessageListener>.of(_listeners)) {
          try {
            await listener.onMultiWindowMessage(method, args, fromWindowId);
          } catch (err, stack) {
            logger.error(_tag, err, stack);
          }
        }
      } catch (err, stack) {
        logger.error(_tag, err, stack);
      }
      return null;
    });
  }

  /// 规范化 MethodChannel 参数为 Map。
  Map<String, dynamic> _parseArguments(dynamic raw) {
    if (raw == null || raw == '') {
      return const {};
    }
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.cast<String, dynamic>();
      }
      throw FormatException('Method arguments JSON must be a Map, got ${decoded.runtimeType}');
    }
    if (raw is Map) {
      return raw.cast<String, dynamic>();
    }
    throw FormatException('Unsupported method arguments type: ${raw.runtimeType}');
  }
}

/// 兼容旧调用点的顶层访问器（懒加载，无 import 副作用）。
MultiWindowDispatchService get multiWindowMsgDispatchService => MultiWindowDispatchService.instance;
