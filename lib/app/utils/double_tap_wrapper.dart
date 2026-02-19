import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart';

/// 双击/单击包装器，可直接用于 GestureDetector.onTap
class DoubleTapWrapper {
  final void Function(TapDownDetails? details)? _onTap;
  final void Function(TapDownDetails? details)? _onDoubleTap;
  final Duration _doubleTapInterval;
  bool _readyDoubleClick = false;

  DoubleTapWrapper({
    void Function(TapDownDetails? details)? onTap,
    void Function(TapDownDetails? details)? onDoubleTap,
    Duration doubleTapInterval = const Duration(milliseconds: 300),
  }) : _doubleTapInterval = doubleTapInterval,
       _onDoubleTap = onDoubleTap,
       _onTap = onTap;

  /// 创建点击处理函数，可直接赋值给onTap
  VoidCallback get wrapperTap => () => _handleTap(null);

  /// 直接调用触发点击逻辑
  void call([TapDownDetails? details]) => _handleTap(details);

  void _handleTap(TapDownDetails? details) {
    if (_onDoubleTap == null) {
      _onTap?.call(details);
      return;
    }
    //设置了双击，且已经点击过一次，执行双击逻辑
    if (_readyDoubleClick) {
      _onDoubleTap.call(details);
      //双击结束，恢复状态
      _readyDoubleClick = false;
    } else {
      _readyDoubleClick = true;
      //设置了双击，但仅点击了一次，延迟一段时间
      Future.delayed(_doubleTapInterval, () {
        if (_readyDoubleClick) {
          //指定时间后仍然没有进行第二次点击，进行单击逻辑
          _onTap?.call(details);
        }
        //指定时间后无论是否双击，恢复状态
        _readyDoubleClick = false;
      });
    }
  }
}
