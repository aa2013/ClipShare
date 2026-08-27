import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/widgets/drag_pending_file_list_item.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

class PendingFileList extends StatelessWidget {
  final List<DropItem> pendingItems;
  final void Function(DropItem item) onItemRemove;
  final void Function() onAddClicked;
  final void Function() onClearAllClicked;

  const PendingFileList({
    super.key,
    required this.pendingItems,
    required this.onItemRemove,
    required this.onAddClicked,
    required this.onClearAllClicked,
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
                        onPressed: onClearAllClicked,
                        icon: const Icon(Icons.clear_all_outlined),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
              Text(TranslationKey.pendingFileLen.trParams({"len": pendingItems.length.toString()})),
            ],
          ),
        ),
        Expanded(
          child: Visibility(
            visible: pendingItems.isNotEmpty,
            replacement: EmptyContent(
              icon: const Icon(
                Icons.file_upload_outlined,
                size: 50,
                color: Colors.blueGrey,
              ),
              description: TranslationKey.dragFileToSend.tr,
              descriptionTextColor: Colors.blueGrey,
            ),
            child: ListView(
              children: pendingItems
                  .map(
                    (item) =>
                    DragPendingFileListItem(
                      item: item,
                      onRemove: onItemRemove,
                    ),
              )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            IconButton(
              onPressed: onAddClicked,
              tooltip: TranslationKey.addFilesFromSystem.tr,
              icon: Row(
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
