import 'package:clipshare/core/services/transport/file/models/file_transfer_task.dart';
import 'package:clipshare/features/file_transfer/widgets/transfer_progress_bar.dart';
import 'package:clipshare/features/file_transfer/widgets/transfer_task_card.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/extensions/number_extension.dart';
import 'package:flutter/material.dart';

class _FolderNode {
  final List<FileTransferTask> files = [];
  final Map<String, _FolderNode> children = {};

  List<FileTransferTask> collectTasks() {
    return [
      ...files,
      for (final child in children.values) ...child.collectTasks(),
    ];
  }

  /// 子树聚合大小与进度
  int get totalSize => collectTasks().fold(0, (prev, task) => prev + task.totalSize);

  int get transferredSum => collectTasks().fold(0, (prev, task) => prev + task.transferredBytes);

  bool get hasError => collectTasks().any((task) => task.state == .error);

  bool get hasCancellable => collectTasks().any((task) => task.cancellable);
}

/// 依据组内任务的协议文件名构建文件夹树，[groupKey] 为顶层目录前缀
_FolderNode _buildFolderTree(List<FileTransferTask> tasks, String groupKey) {
  final root = _FolderNode();
  for (final task in tasks) {
    var relative = task.fileName;
    if (groupKey.isNotEmpty && task.fileName.startsWith('$groupKey/')) {
      relative = task.fileName.substring(groupKey.length + 1);
    }
    final segments = relative.split('/');
    var node = root;
    for (var i = 0; i < segments.length - 1; i++) {
      node = node.children.putIfAbsent(segments[i], () => _FolderNode());
    }
    node.files.add(task);
  }
  return root;
}

/// 文件夹分组卡片：默认折叠展示聚合进度，展开后按层级渲染文件与子文件夹，
/// 子文件夹可继续展开，组内任意层级均可终止
class TransferGroupTile extends StatefulWidget {
  /// 组内任务（同设备同顶层目录），至少一个
  final List<FileTransferTask> tasks;

  /// 组级终止回调
  final VoidCallback? onCancelGroup;

  /// 单文件终止回调
  final ValueChanged<FileTransferTask>? onTaskCancel;

  const TransferGroupTile({
    super.key,
    required this.tasks,
    this.onCancelGroup,
    this.onTaskCancel,
  });

  @override
  State<TransferGroupTile> createState() => _TransferGroupTileState();
}

class _TransferGroupTileState extends State<TransferGroupTile> {
  static const borderRadius = 12.0;
  var _expanded = false;

  FileTransferTask get _first => widget.tasks.first;

  @override
  Widget build(BuildContext context) {
    final groupKey = _first.groupKey ?? '';
    final root = _buildFolderTree(widget.tasks, groupKey);
    final totalSize = root.totalSize;
    final transferredSum = root.transferredSum;
    final cancellable = widget.tasks.any((task) => task.cancellable);
    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    color: Colors.blueGrey,
                    Icons.folder_outlined,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupKey,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_first.devName} · ${_doneCount(widget.tasks)}/${widget.tasks.length}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  if (cancellable && widget.onCancelGroup != null)
                    Tooltip(
                      message: TranslationKey.stop.tr,
                      child: IconButton(
                        onPressed: widget.onCancelGroup,
                        icon: const Icon(
                          color: Colors.red,
                          Icons.stop_circle_outlined,
                        ),
                      ),
                    ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TransferProgressBar(
                factor: totalSize <= 0 ? 0 : transferredSum / totalSize,
                error: root.hasError,
                leftTexts: [totalSize.sizeStr],
                rightTexts: ['${totalSize <= 0 ? 0 : transferredSum * 100 ~/ totalSize}%'],
              ),
              if (_expanded) ...[
                const SizedBox(height: 10),
                _FolderChildren(
                  node: root,
                  displayPrefix: groupKey,
                  onTaskCancel: widget.onTaskCancel,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 已结束（完成/取消/失败）的任务数
  int _doneCount(List<FileTransferTask> tasks) {
    return tasks.where((task) => task.state != .pending && task.state != .transferring).length;
  }
}

class _FolderChildren extends StatelessWidget {
  final _FolderNode node;

  /// 展示名剔除的路径前缀（逐层累加）
  final String displayPrefix;
  final ValueChanged<FileTransferTask>? onTaskCancel;

  const _FolderChildren({
    required this.node,
    required this.displayPrefix,
    this.onTaskCancel,
  });

  @override
  Widget build(BuildContext context) {
    final childEntries = node.children.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return Column(
      children: [
        for (final task in node.files)
          TransferTaskCard(
            task: task,
            displayPrefix: displayPrefix,
            onCancel: onTaskCancel == null ? null : () => onTaskCancel!(task),
          ),
        for (final entry in childEntries)
          _SubFolderTile(
            name: entry.key,
            node: entry.value,
            displayPrefix: '$displayPrefix/${entry.key}',
            onTaskCancel: onTaskCancel,
          ),
      ],
    );
  }
}

class _SubFolderTile extends StatefulWidget {
  final String name;
  final _FolderNode node;

  /// 展示名剔除的路径前缀（逐层累加）
  final String displayPrefix;
  final ValueChanged<FileTransferTask>? onTaskCancel;

  const _SubFolderTile({
    required this.name,
    required this.node,
    required this.displayPrefix,
    this.onTaskCancel,
  });

  @override
  State<_SubFolderTile> createState() => _SubFolderTileState();
}

class _SubFolderTileState extends State<_SubFolderTile> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final subtreeTasks = node.collectTasks();
    final cancellable = subtreeTasks.any((task) => task.cancellable);
    final totalSize = node.totalSize;
    final transferredSum = node.transferredSum;
    final percent = totalSize <= 0 ? 0 : transferredSum * 100 ~/ totalSize;
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Card(
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      color: Colors.blueGrey,
                      Icons.folder_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${subtreeTasks.length} 项 · $percent%',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (cancellable && widget.onTaskCancel != null)
                      Tooltip(
                        message: TranslationKey.stop.tr,
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            for (final task in subtreeTasks) {
                              if (task.cancellable) {
                                widget.onTaskCancel!(task);
                              }
                            }
                          },
                          icon: const Icon(
                            color: Colors.red,
                            Icons.stop_circle_outlined,
                            size: 20,
                          ),
                        ),
                      ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TransferProgressBar(
                  factor: totalSize <= 0 ? 0 : transferredSum / totalSize,
                  error: node.hasError,
                  leftTexts: [totalSize.sizeStr],
                  rightTexts: ['$percent%'],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 10),
                  _FolderChildren(
                    node: node,
                    displayPrefix: widget.displayPrefix,
                    onTaskCancel: widget.onTaskCancel,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
