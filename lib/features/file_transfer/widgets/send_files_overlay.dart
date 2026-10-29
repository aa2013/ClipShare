import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/services/transport/file/models/pending_transfer_file.dart';
import 'package:clipshare/features/file_transfer/widgets/device_selector.dart';
import 'package:clipshare/features/file_transfer/widgets/pending_file_list.dart';
import 'package:clipshare/shared/extensions/context_extension.dart';
import 'package:flutter/material.dart';

/// 新建发送遮罩层：桌面端左右布局（设备多选 | 待发文件），
/// 移动端上下布局（设备在上、文件在下）。
/// 待发文件与选中设备状态由 sendComposeProvider 持有，本组件仅做展示与回调。
class SendFilesOverlay extends StatelessWidget {
  final List<Device> devices;
  final Set<String> selectedDevIds;
  final ValueChanged<Device> onToggleDevice;
  final List<PendingTransferFile> files;
  final ValueChanged<PendingTransferFile> onRemoveFile;
  final VoidCallback onAddFiles;
  final VoidCallback onClearAll;

  const SendFilesOverlay({
    super.key,
    required this.devices,
    required this.selectedDevIds,
    required this.onToggleDevice,
    required this.files,
    required this.onRemoveFile,
    required this.onAddFiles,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final selector = DeviceSelector(
      devices: devices,
      selectedIds: selectedDevIds,
      onToggle: onToggleDevice,
    );
    final pendingList = PendingFileList(
      files: files,
      onRemove: onRemoveFile,
      onAddFiles: onAddFiles,
      onClearAll: onClearAll,
    );
    if (context.isCompactScreen) {
      return Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 155, child: selector),
              Expanded(child: pendingList),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 30, right: 30, bottom: 30),
      child: Row(
        children: [
          SizedBox(width: 280, child: selector),
          Expanded(child: pendingList),
        ],
      ),
    );
  }
}
