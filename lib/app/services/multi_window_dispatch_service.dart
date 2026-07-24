import 'dart:async';
import 'dart:convert';

import 'package:clipshare/app/data/enums/channelMethods/multi_window_method.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class MultiWindowMessageListener {
  FutureOr<void> onMultiWindowMessage(MultiWindowMethod method, Map<String,dynamic> args, int fromWindowId);
}

class MultiWindowDispatchService {
  final Set<MultiWindowMessageListener> _listeners = {};

  MultiWindowDispatchService._private() {
    _initMethodHandler();
  }

  void addListener(MultiWindowMessageListener listener) {
    _listeners.add(listener);
  }

  void removeListener(MultiWindowMessageListener listener) {
    _listeners.remove(listener);
  }

  void _initMethodHandler() {
    DesktopMultiWindow.setMethodHandler((
      MethodCall call,
      int fromWindowId,
    ) async {
      var args = (jsonDecode(call.arguments) as Map<dynamic, dynamic>).cast<String, dynamic>();
      var method = MultiWindowMethod.values.byName(call.method);
      for(var listener in _listeners){
        try {
          await listener.onMultiWindowMessage(method, args, fromWindowId);
        } catch (err, stack) {
          debugPrint(err.toString());
          debugPrintStack(stackTrace: stack);
        }
      }
    });
  }
}

final multiWindowMsgDispatchService = MultiWindowDispatchService._private();
