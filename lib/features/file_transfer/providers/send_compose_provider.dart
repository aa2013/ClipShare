import 'package:clipshare/core/services/transport/file/models/pending_transfer_file.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_compose_provider.g.dart';

/// 新建发送的临时状态：待发文件、选中设备与遮罩开关。
/// 由首页整窗拖拽与文件传输页添加入口共同驱动，遮罩在首页层级展示。
class SendComposeState {
  final bool overlayVisible;
  final List<PendingTransferFile> files;
  final Set<String> selectedDevIds;

  const SendComposeState({
    this.overlayVisible = false,
    this.files = const [],
    this.selectedDevIds = const {},
  });

  SendComposeState copyWith({
    bool? overlayVisible,
    List<PendingTransferFile>? files,
    Set<String>? selectedDevIds,
  }) {
    return SendComposeState(
      overlayVisible: overlayVisible ?? this.overlayVisible,
      files: files ?? this.files,
      selectedDevIds: selectedDevIds ?? this.selectedDevIds,
    );
  }
}

@Riverpod(keepAlive: true)
class SendComposeNotifier extends _$SendComposeNotifier {
  @override
  SendComposeState build() {
    return const SendComposeState();
  }

  /// 打开遮罩
  void openOverlay() {
    state = state.copyWith(overlayVisible: true);
  }

  /// 关闭遮罩
  void closeOverlay() {
    state = state.copyWith(overlayVisible: false);
  }

  /// 追加待发文件，同一路径只保留一个条目
  void addFiles(List<PendingTransferFile> files) {
    final merged = [...state.files];
    for (final file in files) {
      if (!merged.any((item) => item.filePath == file.filePath)) {
        merged.add(file);
      }
    }
    state = state.copyWith(files: merged);
  }

  /// 移除待发条目
  void removeFile(PendingTransferFile file) {
    state = state.copyWith(
      files: state.files.where((item) => item.filePath != file.filePath).toList(),
    );
  }

  /// 清空待发文件
  void clearFiles() {
    state = state.copyWith(files: []);
  }

  /// 切换设备选中态
  void toggleDevice(String devId) {
    final ids = {...state.selectedDevIds};
    if (!ids.remove(devId)) {
      ids.add(devId);
    }
    state = state.copyWith(selectedDevIds: ids);
  }

  /// 自动选中设备（唯一在线设备场景），幂等
  void selectDevice(String devId) {
    if (state.selectedDevIds.contains(devId)) {
      return;
    }
    state = state.copyWith(selectedDevIds: {...state.selectedDevIds, devId});
  }

  /// 清空选中设备
  void clearDevices() {
    state = state.copyWith(selectedDevIds: {});
  }
}
