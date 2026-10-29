import 'package:clipshare/core/services/transport/file/enums/file_transfer_direction.dart';
import 'package:clipshare/core/services/transport/file/enums/file_transfer_state.dart';

/// 单文件传输任务，发送与接收共用
class FileTransferTask {
  /// 任务 id（uuid），UI 终止操作的定位键
  final String id;

  /// 传输方向
  final FileTransferDirection direction;

  /// 对端设备 id
  final String devId;

  /// 对端设备展示名
  final String devName;

  /// 协议文件名，可携带 "dir/sub/name.ext" 形式的相对路径
  final String fileName;

  /// 本地路径：发送为源路径（uri 场景为 content uri），接收为落盘路径
  final String localPath;

  /// 发送源是否为 content uri
  final bool isUri;

  /// 文件总大小
  final int totalSize;

  /// 协议文件 id（雪花 id），对端据此关联控制消息与文件流
  final int fileId;

  /// 顶层目录分组键（协议文件名首段目录），散文件为 null
  final String? groupKey;

  /// 任务创建时间
  final DateTime startTime;

  /// 以下三项随传输进度原地更新
  int transferredBytes;
  double speed;
  FileTransferState state;

  FileTransferTask({
    required this.id,
    required this.direction,
    required this.devId,
    required this.devName,
    required this.fileName,
    required this.localPath,
    this.isUri = false,
    required this.totalSize,
    required this.fileId,
    required this.groupKey,
    DateTime? startTime,
    this.transferredBytes = 0,
    this.speed = 0,
    this.state = FileTransferState.pending,
  }) : startTime = startTime ?? DateTime.now();

  /// 传输进度（0~1）
  double get progress {
    if (totalSize <= 0) {
      return 0;
    }
    return (transferredBytes / totalSize).clamp(0, 1);
  }

  /// 是否可被用户终止
  bool get cancellable => state == .pending || state == .transferring;
}
