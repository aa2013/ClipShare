import 'dart:async';
import 'dart:io';

import 'package:clipshare/core/services/device/local_device_info.dart';
import 'package:clipshare/core/services/transport/file/models/file_transfer_task.dart';
import 'package:clipshare/shared/extensions/cancellable_extension.dart';
import 'package:clipshare/shared/utils/parallerl_task.dart';
import 'package:uri_file_reader/uri_file_reader.dart';

/// 用户终止传输时由通道抛出，用于中断进行中的文件流
class FileTransferCanceledException implements Exception {
  const FileTransferCanceledException();

  @override
  String toString() => 'FileTransferCanceledException';
}

/// 单文件发送入参
class FileSendJob {
  /// 目标设备（协议路由与消息发送使用）
  final BaseDeviceInfo device;

  /// 传输任务
  final FileTransferTask task;

  /// 取消令牌，通道在关键节点轮询；取消后中断传输并抛出 [FileTransferCanceledException]
  final CancelToken cancelToken;

  /// 字节进度回调，入参为累计已发送字节
  final void Function(int transferredBytes) onProgress;

  const FileSendJob({
    required this.device,
    required this.task,
    required this.cancelToken,
    required this.onProgress,
  });
}

/// 文件发送通道抽象：由具体传输协议实现单文件的流式发送
abstract class FileSendChannel {
  /// 发送单文件；失败或取消时抛出异常，任务状态由调度方统一收口
  Future<void> send(FileSendJob job);
}

/// 打开发送源文件流：content uri 经 uriFileReader 读取，本地文件直接按字节流打开
Future<Stream<List<int>>> openSendSourceStream(String localPath, {required bool isUri}) async {
  if (isUri) {
    final stream = await uriFileReader.readFileAsBytesStream(localPath);
    if (stream == null) {
      throw Exception('read uri file stream failed: $localPath');
    }
    return stream;
  }
  return File(localPath).openRead();
}

/// 为文件流附加进度统计与取消支持。
///
/// 取消时立即结束输出流，下游（socket 写入、HTTP 上传）随之中断，
/// 不需要等待下一个数据块到达。[onProgress] 为空时只做取消支持。
Stream<List<int>> trackFileStream(
  Stream<List<int>> source, {
  required CancelToken cancelToken,
  void Function(int transferredBytes)? onProgress,
}) {
  final progress = onProgress;
  final Stream<List<int>> progressed;
  if (progress == null) {
    progressed = source;
  } else {
    var transferred = 0;
    progressed = source.transform(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (data, sink) {
          transferred += data.length;
          progress(transferred);
          sink.add(data);
        },
      ),
    );
  }
  return progressed.cancellable(
    cancelToken,
    cancelError: () => const FileTransferCanceledException(),
  );
}
