import 'dart:async';
import 'dart:isolate';

import 'package:clipshare/app/modules/settings_module/pages/settings_section_view_base.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:get/get.dart';
import 'package:jieba_flutter/analysis/jieba_segmenter.dart';
import 'package:jieba_flutter/analysis/seg_token.dart';

const _opInit = 'init';
const _opSegment = 'segment';
const _keyRequestId = 'requestId';
const _keyOperation = 'operation';
const _keyDirPath = 'dirPath';
const _keyText = 'text';
const _keyMode = 'mode';
const _keySuccess = 'success';
const _keyData = 'data';
const _keyError = 'error';
const _keyStack = 'stack';

class JiebaSegmentService extends GetxService {
  final tag = 'JiebaSegmentService';

  Isolate? _worker;
  ReceivePort? _receivePort;
  SendPort? _workerSendPort;
  Completer<void>? _startCompleter;
  Future<bool>? _initFuture;
  String? _initializingDirPath;
  String? _initializedDirPath;
  int _nextRequestId = 0;
  final _pendingRequests = <int, Completer<dynamic>>{};
  final _appConfig = Get.find<ConfigService>();

  /// 判断指定词典路径是否已在当前 worker 内初始化，用于避免重复展示初始化 loading。
  bool isInitializedFor(String dirPath) {
    return _initializedDirPath == dirPath && _workerSendPort != null;
  }

  /// 确保分词 worker 已完成词典初始化，同一路径下的并发请求会复用同一个初始化任务。
  Future<bool> ensureInitialized(String dirPath) async {
    if (_initializedDirPath == dirPath && _workerSendPort != null) {
      return true;
    }
    if (_initFuture != null && _initializingDirPath == dirPath) {
      return _initFuture!;
    }
    if (_initFuture != null) {
      await _initFuture;
    }
    if (_initializedDirPath != null && _initializedDirPath != dirPath) {
      _disposeWorker();
    }

    _initializingDirPath = dirPath;
    _initFuture = _initializeWorker(dirPath);
    final result = await _initFuture!;
    if (!result) {
      _initFuture = null;
    }
    _initializingDirPath = null;
    return result;
  }

  /// 使用已初始化的后台 worker 分词，避免在 UI isolate 上执行 Jieba 的重计算逻辑。
  Future<List<SegToken>> segment(
    String text, {
    SegMode mode = SegMode.SEARCH,
  }) async {
    if (_initializedDirPath == null) {
      throw StateError('JiebaSegmentService not initialized');
    }
    final rows = await _sendRequest<List<dynamic>>({
      _keyOperation: _opSegment,
      _keyText: text,
      _keyMode: mode.name,
    });
    return rows.map((row) {
      final token = row as List<dynamic>;
      return SegToken(token[0] as String, token[1] as int, token[2] as int);
    }).toList(growable: false);
  }

  /// 启动 worker 并在后台完成 Jieba 词典加载；失败时释放 worker 以便下次重试。
  Future<bool> _initializeWorker(String dirPath) async {
    try {
      await _ensureWorkerStarted();
      await _sendRequest<bool>({
        _keyOperation: _opInit,
        _keyDirPath: dirPath,
      });
      _initializedDirPath = dirPath;
      return true;
    } catch (err, stack) {
      logger.error(tag, err, stack);
      _disposeWorker(error: err, stack: stack);
      return false;
    }
  }

  /// 懒启动常驻 isolate，首条消息是 worker 用于接收后续请求的 SendPort。
  Future<void> _ensureWorkerStarted() async {
    if (_workerSendPort != null) {
      return;
    }
    if (_startCompleter != null) {
      return _startCompleter!.future;
    }

    final receivePort = ReceivePort();
    _receivePort = receivePort;
    _startCompleter = Completer<void>();
    receivePort.listen(_handleWorkerMessage, onDone: _handleWorkerClosed);

    try {
      _worker = await Isolate.spawn(
        _jiebaSegmentWorker,
        receivePort.sendPort,
        debugName: 'jieba_segment_worker',
        onExit: receivePort.sendPort,
        onError: receivePort.sendPort,
      );
      await _startCompleter!.future;
    } catch (err, stack) {
      _disposeWorker(error: err, stack: stack);
      rethrow;
    } finally {
      if (_startCompleter?.isCompleted == true) {
        _startCompleter = null;
      }
    }
  }

  /// 发送带 requestId 的请求，并把 worker 返回值匹配回对应的 Future。
  Future<T> _sendRequest<T>(Map<String, Object?> payload) async {
    await _ensureWorkerStarted();
    final requestId = ++_nextRequestId;
    final completer = Completer<dynamic>();
    _pendingRequests[requestId] = completer;
    _workerSendPort!.send({
      _keyRequestId: requestId,
      ...payload,
    });
    return await completer.future as T;
  }

  /// 统一处理 worker 初始化握手、成功响应和错误响应。
  void _handleWorkerMessage(dynamic message) {
    if (message == null) {
      _disposeWorker(error: StateError('Jieba worker 已退出'));
      return;
    }
    if (message is List && message.length >= 2) {
      _disposeWorker(error: RemoteError(message[0].toString(), message[1].toString()));
      return;
    }
    if (message is SendPort) {
      _workerSendPort = message;
      if (_startCompleter?.isCompleted == false) {
        _startCompleter!.complete();
      }
      return;
    }
    if (message is! Map) {
      logger.error(tag, '未知的 Jieba worker 消息: $message');
      return;
    }

    final requestId = message[_keyRequestId] as int?;
    final completer = _pendingRequests.remove(requestId);
    if (completer == null) {
      return;
    }
    if (message[_keySuccess] == true) {
      completer.complete(message[_keyData]);
    } else {
      completer.completeError(
        RemoteError(
          message[_keyError]?.toString() ?? 'Jieba worker 请求失败',
          message[_keyStack]?.toString() ?? '',
        ),
      );
    }
  }

  /// worker 异常关闭时唤醒所有等待方，避免调用方 Future 永久挂起。
  void _handleWorkerClosed() {
    _disposeWorker(error: StateError('Jieba worker 已关闭'));
  }

  /// 释放 isolate 和所有挂起请求；初始化失败或服务销毁时都走这里收口。
  void _disposeWorker({Object? error, StackTrace? stack}) {
    final disposeError = error ?? StateError('Jieba worker 已释放');
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(disposeError, stack);
      }
    }
    _pendingRequests.clear();
    if (_startCompleter?.isCompleted == false) {
      _startCompleter!.completeError(disposeError, stack);
    }
    _receivePort?.close();
    _worker?.kill(priority: Isolate.immediate);
    _receivePort = null;
    _worker = null;
    _workerSendPort = null;
    _startCompleter = null;
    _initFuture = null;
    _initializingDirPath = null;
    _initializedDirPath = null;
  }

  @override
  void onClose() {
    _disposeWorker();
    super.onClose();
  }


  ///获取分词文件的存储位置
  Future<String> getJiebaSegmentFileDirPath() async {
    late String dirPath;
    if (Platform.isWindows) {
      dirPath = Directory(Platform.resolvedExecutable).parent.path;
      if (!FileUtil.testWriteable(dirPath)) {
        dirPath = _appConfig.documentsPath;
      }
    } else {
      dirPath = _appConfig.documentsPath;
    }
    return "$dirPath/jieba".normalizePath;
  }

  ///检测是否可分词
  Future<bool> checkJiebaSegment(BuildContext context) async {
    final dirPath = await getJiebaSegmentFileDirPath();
    final dictFilePath = "$dirPath/dict.txt".normalizePath;
    final probEmitFilePath = "$dirPath/prob_emit.txt".normalizePath;
    final result = await File(dictFilePath).exists() && await File(probEmitFilePath).exists();
    if (!result) return false;
    final segmentService = Get.find<JiebaSegmentService>();
    if (segmentService.isInitializedFor(dirPath)) {
      return true;
    }
    if (!context.mounted) {
      return false;
    }
    final dialog = Global.showLoadingDialog(
        context: context,
        loadingText: TranslationKey.loading.tr
    );
    try {
      // Jieba 初始化会解析大词典，交给分词服务的后台 isolate，避免阻塞 UI isolate。
      return await segmentService.ensureInitialized(dirPath);
    } catch (err, stack) {
      logger.error(tag, err, stack);
      return false;
    } finally {
      await dialog.close();
    }
  }

}

/// 常驻后台入口：Jieba 的静态词典状态保留在这个 isolate 内，后续分词复用同一份模型。
Future<void> _jiebaSegmentWorker(SendPort mainSendPort) async {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  var initialized = false;
  await for (final message in receivePort) {
    if (message is! Map) {
      continue;
    }
    final requestId = message[_keyRequestId] as int;
    try {
      final operation = message[_keyOperation] as String;
      switch (operation) {
        case _opInit:
          await JiebaSegmenter.init(message[_keyDirPath] as String);
          initialized = true;
          mainSendPort.send({
            _keyRequestId: requestId,
            _keySuccess: true,
            _keyData: true,
          });
          break;
        case _opSegment:
          if (!initialized) {
            throw StateError('Jieba worker 尚未初始化');
          }
          final mode = SegMode.values.byName(message[_keyMode] as String);
          final segmenter = JiebaSegmenter();
          final tokens = segmenter
              .process(message[_keyText] as String, mode)
              .map((token) => [
                    token.word,
                    token.startOffset,
                    token.endOffset,
                  ])
              .toList(growable: false);
          mainSendPort.send({
            _keyRequestId: requestId,
            _keySuccess: true,
            _keyData: tokens,
          });
          break;
        default:
          throw UnsupportedError('未知的 Jieba worker 操作: $operation');
      }
    } catch (err, stack) {
      mainSendPort.send({
        _keyRequestId: requestId,
        _keySuccess: false,
        _keyError: err.toString(),
        _keyStack: stack.toString(),
      });
    }
  }
}
