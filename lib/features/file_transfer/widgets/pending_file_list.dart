import 'package:clipshare/core/services/transport/file/models/pending_transfer_file.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/widgets/base/empty_content.dart';
import 'package:flutter/material.dart';

/// 待发送文件列表：展示已加入队列的文件与操作（移除/清空/添加）
class PendingFileList extends StatelessWidget {
  final List<PendingTransferFile> files;
  final ValueChanged<PendingTransferFile> onRemove;
  final VoidCallback onAddFiles;
  final VoidCallback onClearAll;

  const PendingFileList({
    super.key,
    required this.files,
    required this.onRemove,
    required this.onAddFiles,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(left: 5, right: 5, bottom: 1),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.file_copy_outlined,
                      size: 17,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      TranslationKey.pendingFiles.tr,
                      style: const TextStyle(fontSize: 17),
                    ),
                    const SizedBox(width: 5),
                    Tooltip(
                      message: TranslationKey.clearPendingFiles.tr,
                      child: IconButton(
                        onPressed: onClearAll,
                        icon: const Icon(Icons.clear_all_outlined),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
              Text(TranslationKey.pendingFileLen.trParams({'len': files.length.toString()})),
            ],
          ),
        ),
        Expanded(
          child: Visibility(
            visible: files.isNotEmpty,
            replacement: EmptyContent(
              icon: const Icon(
                Icons.file_upload_outlined,
                size: 50,
                color: Colors.blueGrey,
              ),
              description: TranslationKey.dragFileToSend.tr,
              descriptionTextColor: Colors.blueGrey,
            ),
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (ctx, idx) {
                final file = files[idx];
                return _PendingFileListItem(
                  file: file,
                  onRemove: () => onRemove(file),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            IconButton(
              onPressed: onAddFiles,
              tooltip: TranslationKey.addFilesFromSystem.tr,
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add,
                    color: Colors.blueGrey,
                  ),
                  Text(TranslationKey.add.tr),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PendingFileListItem extends StatelessWidget {
  static const borderRadius = 12.0;

  final PendingTransferFile file;
  final VoidCallback onRemove;

  const _PendingFileListItem({
    required this.file,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: InkWell(
        mouseCursor: SystemMouseCursors.basic,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(
                file.isDirectory ? Icons.folder_outlined : Icons.file_present_outlined,
                color: Colors.blueGrey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.fileName,
                      style: const TextStyle(fontSize: 17),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      //文件夹条目展示类型文案，文件展示大小
                      file.isDirectory ? TranslationKey.folder.tr : file.size.sizeStr,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w100),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: TranslationKey.removeFromPendingList.tr,
                child: IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
