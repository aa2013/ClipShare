import 'dart:async';
import 'dart:io';

import 'package:clipshare/app/data/models/my_drop_item.dart' as pending_drop;
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/widgets/base/custom_title_bar_layout.dart';
import 'package:flutter/material.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

/// 使用 super_drag_and_drop 接收桌面文件拖入，并转换为项目既有的 DropItemFile。
///
/// ClipNativeDragItemWrapper 会初始化 super_drag_and_drop 的原生 DropContext，
/// 若首页继续使用另一个原生拖放接收器，会在同一窗口内出现原生拖放上下文冲突。
class NativeFileDropRegion extends StatelessWidget {
  static const _fileUriReadTimeout = Duration(seconds: 10);

  final Widget child;
  final VoidCallback? onDragEntered;
  final VoidCallback? onDragExited;
  final ValueChanged<List<pending_drop.DropItem>> onDropDone;

  const NativeFileDropRegion({
    super.key,
    required this.child,
    required this.onDropDone,
    this.onDragEntered,
    this.onDragExited,
  });

  @override
  Widget build(BuildContext context) {
    final region = DropRegion(
      formats: const [Formats.fileUri],
      hitTestBehavior: HitTestBehavior.opaque,
      onDropEnter: (_) => onDragEntered?.call(),
      onDropLeave: (_) => onDragExited?.call(),
      onDropEnded: (_) => onDragExited?.call(),
      onDropOver: _handleDropOver,
      onPerformDrop: _handlePerformDrop,
      child: child,
    );
    if (Platform.isMacOS) {
      return Padding(
        padding: Constants.macOSSafeAreaHeight.insetT,
        child: region,
      );
    }
    return region;
  }

  /// 仅接受包含本地文件 URI 的拖拽，避免普通文本或链接误触发文件发送遮罩。
  DropOperation _handleDropOver(DropOverEvent event) {
    final hasFileUri = event.session.items.any(
      (item) => item.canProvide(Formats.fileUri),
    );
    if (!hasFileUri) {
      return DropOperation.none;
    }
    final allowedOperations = event.session.allowedOperations;
    if (allowedOperations.isEmpty || allowedOperations.contains(DropOperation.copy)) {
      return DropOperation.copy;
    }
    return allowedOperations.first;
  }

  /// 将 super_drag_and_drop 的 DropItem 读取为本地文件路径并复用待发送列表逻辑。
  Future<void> _handlePerformDrop(PerformDropEvent event) async {
    final files = <pending_drop.DropItem>[];
    for (final item in event.session.items) {
      final uri = await _readFileUri(item);
      if (uri == null || !uri.isScheme('file')) {
        continue;
      }
      files.add(pending_drop.DropItemFile(uri.toFilePath()));
    }
    if (files.isNotEmpty) {
      onDropDone(files);
    }
  }

  /// 读取单个拖拽项的文件 URI；读取失败或超时按不可用处理。
  Future<Uri?> _readFileUri(DropItem item) async {
    final reader = item.dataReader;
    if (reader == null || !reader.canProvide(Formats.fileUri)) {
      return null;
    }
    final completer = Completer<Uri?>();
    final progress = reader.getValue<Uri>(
      Formats.fileUri,
      (value) {
        if (!completer.isCompleted) {
          completer.complete(value);
        }
      },
      onError: (_) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    );
    if (progress == null) {
      return null;
    }
    return completer.future.timeout(
      _fileUriReadTimeout,
      onTimeout: () => null,
    );
  }
}

