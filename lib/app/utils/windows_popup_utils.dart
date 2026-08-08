import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// 给当前进程的 Flutter 子窗口（弹窗）添加 WS_EX_NOACTIVATE 扩展样式。
///
/// 添加后弹窗在显示时不会被激活、不抢占前台焦点，避免打断用户在外部
/// 应用中的输入（例如复制后弹出历史弹窗时，用户输入焦点仍停留在原应用）。
void applyNoActivateToCurrentWindow() {
  final lpClassName = 'FlutterMultiWindow'.toNativeUtf16();
  try {
    final hwnd = FindWindow(lpClassName, nullptr);
    if (hwnd == 0) {
      return;
    }
    final exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
    SetWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle | WS_EX_NOACTIVATE);
  } finally {
    malloc.free(lpClassName);
  }
}
