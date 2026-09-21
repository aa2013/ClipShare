import 'dart:convert';
import 'dart:io';

import 'package:clipshare/core/database/extensions/history_extension.dart';
import 'package:clipshare/core/database/tables/history.dart';
import 'package:clipshare/core/extensions/file_extension.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

/// 使历史卡片可作为原生拖拽源，拖出到资源管理器或文本输入框。
///
/// 图片/文件按文件拖出；文本默认拖出纯文本，按住 Ctrl 时拖出为虚拟 txt 文件。
/// Windows 与部分目标控件会优先消费虚拟文件格式，若同时注册纯文本与虚拟文件，
/// 可能导致输入框拿不到纯文本，因此文本仅在按住 Ctrl 时才注册虚拟文件。
class HistoryNativeDragItemWrapper extends StatelessWidget {
  final History history;
  final Widget child;

  const HistoryNativeDragItemWrapper({
    super.key,
    required this.history,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final String fileName;
    final File? file;
    if (history.isImage || history.isFile) {
      file = File(history.content);
      fileName = file.fileName;
    } else {
      file = null;
      fileName = 'clipshare-${history.id}.txt';
    }
    return DragItemWidget(
      allowedOperations: () => [DropOperation.copy],
      dragItemProvider: (request) async {
        DragItem? item;
        if (file == null) {
          item = DragItem(
            suggestedName: fileName,
            localData: {'type': 'clipshare-history-text'},
          );
          final content = history.isNotification
              ? (history.notificationContent ?? '')
              : history.content;
          if (_shouldDragTextAsVirtualFile(item)) {
            item.addVirtualFile(
              format: Formats.plainTextFile,
              provider: (sinkProvider, progress) {
                final bytes = utf8.encode(content);
                final sink = sinkProvider(fileSize: bytes.length);
                sink.add(bytes);
                sink.close();
              },
            );
          } else {
            item.add(Formats.plainText(content));
          }
        } else {
          // 本地文件已被删除时取消拖拽
          if (!await file.exists()) {
            return null;
          }
          item = DragItem(
            suggestedName: fileName,
            localData: {
              'type': 'clipshare-history-${history.type.toLowerCase()}',
            },
          );
          item.add(Formats.fileUri(file.uri));
          if (history.isImage) {
            item.add(Formats.png.lazy(file.readAsBytes));
          }
        }
        return item;
      },
      child: DraggableWidget(child: child),
    );
  }

  /// 判断文本历史是否按文件形式拖出；按键修饰代表用户明确想要生成 txt 文件。
  ///
  /// Windows 和部分目标控件会优先消费虚拟文件格式，若同时注册纯文本和虚拟文件，
  /// 可能导致输入框拿不到纯文本，甚至触发虚拟文件流后卡死。
  bool _shouldDragTextAsVirtualFile(DragItem item) {
    final keyboard = HardwareKeyboard.instance;
    return item.virtualFileSupported && keyboard.isControlPressed;
  }
}
