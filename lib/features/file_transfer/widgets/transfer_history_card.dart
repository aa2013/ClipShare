import 'dart:io';

import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/extensions/file_extension.dart';
import 'package:clipshare/features/file_transfer/widgets/transfer_progress_bar.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/time_extension.dart';
import 'package:clipshare/shared/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:open_file_plus/open_file_plus.dart';

/// 历史文件卡片：展示历史发送/接收完成的文件记录，支持打开文件、打开文件夹与多选
class TransferHistoryCard extends StatelessWidget {
  static const borderRadius = 12.0;

  final History history;

  /// 是否为本机发出的文件（区别于从对端接收）
  final bool isSent;

  final bool selectMode;
  final bool selected;

  /// 多选模式下的切换选中回调
  final VoidCallback? onToggleSelected;

  /// 长按进入多选
  final VoidCallback? onLongPress;

  const TransferHistoryCard({
    super.key,
    required this.history,
    required this.isSent,
    this.selectMode = false,
    this.selected = false,
    this.onToggleSelected,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final history = this.history;
    final file = File(history.content);
    final selectMode = this.selectMode;
    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(TransferHistoryCard.borderRadius),
        mouseCursor: SystemMouseCursors.basic,
        onTap: selectMode
            ? onToggleSelected
            : () {
                //桌面端以双击打开文件，移动端单击即打开
                if (context.isCompactScreen) {
                  _openFile(context, file);
                }
              },
        onDoubleTap: selectMode
            ? null
            : () {
                if (!context.isCompactScreen) {
                  _openFile(context, file);
                }
              },
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      file.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    isSent ? Icons.upload : Icons.download,
                    color: isSent ? Colors.green : Colors.blue,
                  ),
                  if (selectMode)
                    IconButton(
                      icon: Icon(
                        selected ? Icons.check_box : Icons.check_box_outline_blank,
                        color: const Color(0xFF33A0E3),
                      ),
                      onPressed: onToggleSelected,
                    )
                  else
                    Tooltip(
                      message: TranslationKey.openFolder.tr,
                      child: IconButton(
                        onPressed: () => _openFolder(file),
                        icon: const Icon(
                          color: Colors.blueGrey,
                          Icons.folder_copy_outlined,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TransferProgressBar(
                factor: 1,
                leftTexts: [history.size.sizeStr],
                rightTexts: [
                  DateTime.parse(history.time).simpleStr,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 打开本地文件，不存在时提示
  Future<void> _openFile(BuildContext context, File file) async {
    if (!file.existsSync()) {
      snackbar.warn(context, TranslationKey.fileNotFound.tr);
      return;
    }
    snackbar.success(context, TranslationKey.openingFile.tr);
    await OpenFile.open(file.normalizePath);
  }

  /// 打开文件所在文件夹
  Future<void> _openFolder(File file) async {
    await OpenFile.open(file.parent.normalizePath);
  }
}
