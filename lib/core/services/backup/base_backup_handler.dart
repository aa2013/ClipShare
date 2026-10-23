import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:clipshare/core/services/backup/backup_type.dart';
import 'package:clipshare/core/services/backup/backup_version_info.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';

/// 单条恢复记录完成落库的回调，参数为 restore 返回的跟踪 id
typedef OnRestoreDone = void Function(int restoreId);

/// 备份项处理器抽象，每个备份项对应一个实现
abstract mixin class BaseBackupHandler {
  /// 备份项类型
  BackupType get backupType;

  /// 从数据库读取备份数据，逐条产出 msgpack 序列化字节
  Stream<Uint8List> loadData(Directory tempDir);

  /// 从备份数据恢复到数据库
  ///
  /// [cancelToken] 恢复取消令牌，[onDone] 在单条记录落库后回调，
  /// 返回值作为恢复进度跟踪 id，null 表示本条无需跟踪
  FutureOr<int?> restore(
    Uint8List bytes,
    BackupVersionInfo version,
    Directory tempDir,
    CancelToken cancelToken,
    OnRestoreDone onDone,
  );
}
