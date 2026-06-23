import 'dart:ui';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:flutter/material.dart';

/// 中转能力的对外展示状态。
enum ForwardServerStatus { initializing, connecting, connected, disconnected }

extension ForwardServerStatusExt on ForwardServerStatus {
  Color get color {
    switch (this) {
      case ForwardServerStatus.initializing:
        return Colors.amber;
      case ForwardServerStatus.connecting:
        return Colors.lime;
      case ForwardServerStatus.connected:
        return Colors.green;
      case ForwardServerStatus.disconnected:
        return Colors.grey;
    }
  }

  String get tr {
    switch (this) {
      case ForwardServerStatus.initializing:
        return TranslationKey.initializing.tr;
      case ForwardServerStatus.connecting:
        return TranslationKey.connecting.tr;
      case ForwardServerStatus.connected:
        return TranslationKey.connected.tr;
      case ForwardServerStatus.disconnected:
        return TranslationKey.disconnected.tr;
    }
  }
}
