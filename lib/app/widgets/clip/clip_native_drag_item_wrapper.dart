import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class ClipNativeDragItemWrapper extends StatelessWidget {
  final ClipData clip;
  final Widget child;

  const ClipNativeDragItemWrapper({
    super.key,
    required this.clip,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final String fileName;
    final File? file;
    if (clip.isImage || clip.isFile) {
      file = File(clip.data.content);
      fileName = file.fileName;
    } else {
      file = null;
      fileName = "clipshare-${clip.data.id}.txt";
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
          final String content;
          if (clip.isNotification) {
            content = clip.notificationContent ?? "";
          } else {
            content = clip.data.content;
          }
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
          //文件不存在
          if (!await file.exists()) {
            return null;
          }
          item = DragItem(
            suggestedName: fileName,
            localData: {
              'type': 'clipshare-history-${clip.data.type.toLowerCase()}',
            },
          );
          item.add(Formats.fileUri(file.uri));
          if (clip.isImage) {
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
