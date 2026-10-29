import 'package:clipshare/core/services/transport/file/models/file_transfer_task.dart';
import 'package:clipshare/features/file_transfer/widgets/transfer_progress_bar.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:clipshare/shared/extensions/time_extension.dart';
import 'package:flutter/material.dart';

/// 传输任务卡片：展示排队/传输中任务的进度、速度与终止操作
class TransferTaskCard extends StatelessWidget {
  static const borderRadius = 12.0;

  final FileTransferTask task;

  /// 终止回调；为 null 时不展示终止按钮
  final VoidCallback? onCancel;

  /// 展示名剔除的路径前缀；为空时剔除顶层目录（组内逐层传递以体现层级）
  final String? displayPrefix;

  const TransferTaskCard({
    super.key,
    required this.task,
    this.onCancel,
    this.displayPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final showSpeed = task.state == .transferring && task.speed > 0;
    final leftTexts = [
      task.totalSize.sizeStr,
      if (showSpeed) '${task.speed.sizeStr}/s',
      if (showSpeed) ((task.totalSize - task.transferredBytes) ~/ task.speed).to24HFormatStr,
    ];
    final rightTexts = [
      _stateText,
      task.startTime.simpleStr,
    ];
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onCancel != null && task.cancellable)
                  Tooltip(
                    message: TranslationKey.stop.tr,
                    child: IconButton(
                      onPressed: onCancel,
                      icon: const Icon(
                        color: Colors.red,
                        Icons.stop_circle_outlined,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TransferProgressBar(
              factor: task.progress,
              error: task.state == .error,
              leftTexts: leftTexts,
              rightTexts: rightTexts,
            ),
          ],
        ),
      ),
    );
  }

  /// 展示名：剔除 [displayPrefix]（缺省为顶层目录）后的相对路径以体现层级，无目录时展示基本名
  String get _displayName {
    final prefix = displayPrefix ?? task.groupKey;
    if (prefix != null && prefix.isNotEmpty && task.fileName.startsWith('$prefix/')) {
      return task.fileName.substring(prefix.length + 1);
    }
    return task.fileName.split(RegExp(r'[/\\]')).last;
  }

  /// 状态展示：排队/异常/取消显示文字，传输中显示百分比
  String get _stateText {
    switch (task.state) {
      case .pending:
        return TranslationKey.waitingTransfer.tr;
      case .error:
        return TranslationKey.failed.tr;
      case .canceled:
        return TranslationKey.transferCanceled.tr;
      case .transferring:
      case .done:
        return '${(task.progress * 10000).round() / 100}%';
    }
  }
}
