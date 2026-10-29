import 'package:clipshare/core/services/transport/file/enums/file_transfer_direction.dart';
import 'package:clipshare/core/services/transport/file/enums/file_transfer_state.dart';
import 'package:clipshare/core/services/transport/file/file_transfer_provider.dart';
import 'package:clipshare/core/services/transport/file/models/file_transfer_task.dart';
import 'package:clipshare/features/file_transfer/providers/send_compose_provider.dart';
import 'package:clipshare/features/file_transfer/utils/pending_file_resolver.dart';
import 'package:clipshare/features/file_transfer/widgets/file_history_list.dart';
import 'package:clipshare/features/file_transfer/widgets/transfer_group_tile.dart';
import 'package:clipshare/features/file_transfer/widgets/transfer_task_card.dart';
import 'package:clipshare/l10n/translation_key.dart';
import 'package:clipshare/shared/utils/file_util.dart';
import 'package:clipshare/shared/utils/snackbar.dart';
import 'package:clipshare/shared/widgets/base/empty_content.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// todo 以下发送入口暂未接入，待基础链路跑通后再补：
// 1. Android 系统分享入口（android_channel_method_call.dart 的 _handleIncomingDropItems）
// 2. 多窗口文件发送（multi_window_channel_method_call.dart 的 MultiWindowMethod.syncFiles）
// 说明：首页整窗拖拽已接入（home_page.dart 的 DropTarget）

/// 文件传输页：历史记录、接收进度、发送进度三个 Tab。
/// 新建发送遮罩与整窗拖拽在首页层级，本页保留"添加"入口。
class FileTransferPage extends ConsumerStatefulWidget {
  const FileTransferPage({super.key});

  @override
  ConsumerState<FileTransferPage> createState() => _FileTransferPageState();
}

class _FileTransferPageState extends ConsumerState<FileTransferPage> with SingleTickerProviderStateMixin {
  static const _historyTabIndex = 0;
  static const _receiveTabIndex = 1;
  static const _sendTabIndex = 2;

  late final TabController _tabController;
  int? _observedTabIndex;
  var _historySelectMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.animation!.addListener(_handleTabAnimated);
  }

  @override
  void dispose() {
    _tabController.animation!.removeListener(_handleTabAnimated);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabAnimated() {
    final index = _tabController.animation!.value.round();
    if (_observedTabIndex == index) {
      return;
    }
    setState(() => _observedTabIndex = index);
  }

  /// 当前 Tab 对应的传输方向；历史 Tab 为 null
  FileTransferDirection? get _currentDirection {
    switch (_observedTabIndex ?? _historyTabIndex) {
      case _receiveTabIndex:
        return .receive;
      case _sendTabIndex:
        return .send;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final compose = ref.watch(sendComposeProvider);
    final currentDirection = _currentDirection;
    final transferTasks = ref.watch(fileTransferProvider);
    final showClearFab =
        currentDirection != null &&
        transferTasks.any(
          (task) => task.direction == currentDirection && (task.state == .canceled || task.state == .error),
        );
    final board = ref.read(fileTransferProvider.notifier);
    final showAddFab = !compose.overlayVisible && compose.files.isEmpty && !_historySelectMode;
    return Stack(
      children: [
        Column(
          children: [
            TabBar(
              controller: _tabController,
              dividerHeight: 0,
              tabs: [
                _buildTab(TranslationKey.syncingFilePageHistoryTabText.tr, Icons.history),
                _buildTab(TranslationKey.syncingFilePageReceiveTabText.tr, Icons.file_download),
                _buildTab(TranslationKey.syncingFilePageSendTabText.tr, Icons.upload),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  FileHistoryList(
                    onSelectModeChanged: (selectMode) {
                      setState(() => _historySelectMode = selectMode);
                    },
                  ),
                  _buildTransferTab(.receive),
                  _buildTransferTab(.send),
                ],
              ),
            ),
          ],
        ),
        //右下角悬浮操作列：清除记录 + 添加文件（同列右对齐，避免重叠）
        Positioned(
          right: 40,
          bottom: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (showClearFab)
                Container(
                  margin: const EdgeInsets.only(right: 5),
                  child: FloatingActionButton(
                    onPressed: () => board.clearFailed(currentDirection),
                    tooltip: TranslationKey.clearFailedTransfers.tr,
                    child: const Icon(Icons.clear_all_outlined),
                  ),
                ),
              Visibility(
                visible: showAddFab,
                child: FloatingActionButton(
                  onPressed: _pickFiles,
                  tooltip: TranslationKey.addFilesFromSystem.tr,
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 选择文件加入待发列表并打开遮罩
  Future<void> _pickFiles() async {
    final picked = await FileUtil.pickFiles();
    final items = picked.where((f) => f.path != null).map((f) => DropItemFile(f.path!)).toList();
    final result = await resolvePendingFiles(items);
    if (!mounted) {
      return;
    }
    if (result.failedCount > 0) {
      snackbar.warn(context, TranslationKey.failedToLoad.tr);
    }
    if (result.files.isEmpty) {
      return;
    }
    final compose = ref.read(sendComposeProvider.notifier);
    compose.addFiles(result.files);
    compose.openOverlay();
  }

  Widget _buildTab(String text, IconData icon) {
    return Tab(
      child: IntrinsicWidth(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text),
            const SizedBox(width: 5),
            Icon(icon, size: 18),
          ],
        ),
      ),
    );
  }

  int _stateOrder(FileTransferState state) {
    return switch (state) {
      .transferring => 0,
      .pending => 1,
      .error => 2,
      .canceled => 3,
      .done => 4,
    };
  }

  int _compareTask(FileTransferTask a, FileTransferTask b) {
    final byState = _stateOrder(a.state).compareTo(_stateOrder(b.state));
    if (byState != 0) {
      return byState;
    }
    return a.devName.compareTo(b.devName);
  }

  /// 构建发送/接收进度 Tab：按顶层目录分组折叠展示，散文件平铺
  Widget _buildTransferTab(FileTransferDirection direction) {
    final tasks = ref.watch(fileTransferProvider).where((task) => task.direction == direction).toList();
    final groups = <String, List<FileTransferTask>>{};
    final looseTasks = <FileTransferTask>[];
    for (final task in tasks) {
      final groupKey = task.groupKey;
      if (groupKey == null) {
        looseTasks.add(task);
      } else {
        groups.putIfAbsent('${task.devId}:$groupKey', () => []).add(task);
      }
    }
    final groupEntries = groups.values.toList()..sort((a, b) => _compareTask(a.first, b.first));
    looseTasks.sort(_compareTask);
    final board = ref.read(fileTransferProvider.notifier);
    return Visibility(
      visible: tasks.isNotEmpty,
      replacement: const Center(child: EmptyContent()),
      child: ListView(
        padding: const EdgeInsets.all(5),
        children: [
          for (final group in groupEntries)
            TransferGroupTile(
              tasks: group,
              onCancelGroup: () => board.cancelGroup(direction, group.first.devId, group.first.groupKey!),
              onTaskCancel: (task) => board.cancelTask(task.id),
            ),
          for (final task in looseTasks)
            TransferTaskCard(
              task: task,
              onCancel: () => board.cancelTask(task.id),
            ),
        ],
      ),
    );
  }
}
