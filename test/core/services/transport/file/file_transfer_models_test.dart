import 'package:clipshare/core/services/transport/file/enums/file_transfer_state.dart';
import 'package:clipshare/core/services/transport/file/models/file_transfer_task.dart';
import 'package:clipshare/core/services/transport/file/models/pending_transfer_file.dart';
import 'package:clipshare/core/services/transport/file/models/protocol/direct_file_msg.dart';
import 'package:clipshare/core/services/transport/file/models/protocol/file_name_codec.dart';
import 'package:clipshare/core/services/transport/file/models/protocol/forward_receiver_ready_msg.dart';
import 'package:clipshare/core/services/transport/file/models/protocol/forward_send_file_msg.dart';
import 'package:clipshare/core/services/transport/file/models/protocol/storage_file_info.dart';
import 'package:clipshare/shared/enums/history_content_type.dart';
import 'package:clipshare/shared/utils/file_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('协议文件名编解码', () {
    test('无目录层级时原样拼接且无分组键', () {
      expect(buildProtocolFileName([], 'a.txt'), 'a.txt');
      expect(parseProtocolFileGroupKey('a.txt'), isNull);
    });

    test('多级目录以 / 拼接并提取顶层分组键', () {
      final name = buildProtocolFileName(['photos', 'sub'], 'a.png');
      expect(name, 'photos/sub/a.png');
      expect(parseProtocolFileGroupKey(name), 'photos');
    });
  });

  group('DirectFileMsg', () {
    test('toJson/fromJson 往返保持字段', () {
      const msg = DirectFileMsg(fileName: 'photos/a.png', size: 1024, port: 8080, fileId: 123);
      final restored = DirectFileMsg.fromJson(msg.toJson());
      expect(restored.fileName, msg.fileName);
      expect(restored.size, msg.size);
      expect(restored.port, msg.port);
      expect(restored.fileId, msg.fileId);
    });
  });

  group('ForwardSendFileMsg', () {
    test('包含中转协议约定的字段与类型', () {
      const msg = ForwardSendFileMsg(
        fileName: 'a.txt',
        size: 10,
        fileId: 5,
        targetDevId: 'dev-2',
        selfDevId: 'dev-1',
      );
      final json = msg.toJson();
      expect(json['fileName'], 'a.txt');
      expect(json['size'], '10');
      expect(json['fileId'], '5');
      expect(json['target'], 'dev-2');
      expect(json['connType'], 'sendFile');
      expect(json['self'], 'dev-1');
    });
  });

  group('ForwardReceiverReadyMsg', () {
    test('wire 值为 recFile 且字段完整', () {
      const msg = ForwardReceiverReadyMsg(targetDevId: 'dev-1', fileId: 5, selfDevId: 'dev-2');
      final json = msg.toJson();
      expect(json['connType'], 'recFile');
      expect(json['target'], 'dev-1');
      expect(json['fileId'], '5');
      expect(json['self'], 'dev-2');
    });
  });

  group('StorageFileInfo', () {
    test('toJson/fromJson 往返保持字段', () {
      const info = StorageFileInfo(fileName: 'sub/a.txt', size: 8);
      final restored = StorageFileInfo.fromJson(info.toJson());
      expect(restored.fileName, info.fileName);
      expect(restored.size, info.size);
    });
  });

  group('FileTransferTask', () {
    test('progress 按已传输字节计算并收敛到 0~1', () {
      FileTransferTask buildTask(int transferred) {
        return FileTransferTask(
          id: 'task-1',
          direction: .send,
          devId: 'dev-1',
          devName: 'dev',
          fileName: 'a.txt',
          localPath: '/tmp/a.txt',
          totalSize: 200,
          fileId: 1,
          groupKey: null,
          transferredBytes: transferred,
        );
      }

      expect(buildTask(0).progress, 0);
      expect(buildTask(100).progress, 0.5);
      expect(buildTask(300).progress, 1);
    });

    test('仅排队与传输中可终止', () {
      FileTransferTask buildTask(FileTransferState state) {
        return FileTransferTask(
          id: 'task-1',
          direction: .send,
          devId: 'dev-1',
          devName: 'dev',
          fileName: 'a.txt',
          localPath: '/tmp/a.txt',
          totalSize: 1,
          fileId: 1,
          groupKey: null,
          state: state,
        );
      }

      expect(buildTask(.pending).cancellable, isTrue);
      expect(buildTask(.transferring).cancellable, isTrue);
      expect(buildTask(.done).cancellable, isFalse);
      expect(buildTask(.canceled).cancellable, isFalse);
      expect(buildTask(.error).cancellable, isFalse);
    });
  });

  group('接收文件名处理', () {
    test('sanitize 保留目录结构并消除路径穿越片段', () {
      final sanitized = FileUtil.sanitizeReceivedFileName('photos/../a.png');
      //按平台路径分隔符拆分
      final parts = sanitized.split(RegExp(r'[/\\]'));
      //包含目录层级且不含穿越片段
      expect(parts.contains('..'), isFalse);
      expect(parts.contains('photos'), isTrue);
      expect(parts.last, 'a.png');
    });

    test('HistoryContentType.file 的值为 File', () {
      expect(HistoryContentType.file.value, 'File');
    });
  });
}
