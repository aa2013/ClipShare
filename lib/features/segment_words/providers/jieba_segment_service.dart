import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:clipshare/core/utils/file_util.dart';
import 'package:clipshare/shared/extensions/string_extension.dart';
import 'package:clipshare/shared/utils/log.dart';
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

/// Jieba 分词服务
///
/// 在常驻 isolate 中加载词典并执行分词，避免 UI isolate 承担重计算
class JiebaSegmentService {
  static const _tag = 'JiebaSegmentService';

  /// 文档目录懒加载回调，用于词典缺失或不可写时回退到文档目录。
  final Future<String> Function() _loadDocumentsPath;

  Isolate? _worker;
  ReceivePort? _receivePort;
  SendPort? _workerSendPort;
  Completer<void>? _startCompleter;
  Future<bool>? _initFuture;
  String? _initializingDirPath;
  String? _initializedDirPath;
  int _nextRequestId = 0;
  final _pendingRequests = <int, Completer<dynamic>>{};

  JiebaSegmentService({
    required Future<String> Function() loadDocumentsPath,
  }) : _loadDocumentsPath = loadDocumentsPath;

  /// 判断指定词典路径是否已在当前 worker 内初始化，用于避免重复展示初始化 loading。
  bool isInitializedFor(String dirPath) {
    return _initializedDirPath == dirPath && _workerSendPort != null;
  }

  /// 确保分词 worker 已完成词典初始化
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
        })
        .toList(growable: false);
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
      logger.error(_tag, err, stack);
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
      _disposeWorker(error: StateError('Jieba worker exited'));
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
      logger.error(_tag, 'Unknown Jieba worker message: $message');
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
          message[_keyError]?.toString() ?? 'Jieba worker request failed',
          message[_keyStack]?.toString() ?? '',
        ),
      );
    }
  }

  /// worker 异常关闭时唤醒所有等待方，避免调用方 Future 永久挂起。
  void _handleWorkerClosed() {
    _disposeWorker(error: StateError('Jieba worker closed'));
  }

  /// 释放 isolate 和所有挂起请求；初始化失败或服务销毁时都走这里收口。
  void _disposeWorker({Object? error, StackTrace? stack}) {
    final disposeError = error ?? StateError('Jieba worker disposed');
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

  /// 释放服务持有的 isolate 资源，由 Riverpod onDispose 调用。
  void dispose() {
    _disposeWorker();
  }

  /// 获取分词文件的存储位置。
  ///
  /// Windows 优先使用可执行文件所在目录（便携版），不可写时回退到文档目录；
  /// 其他平台统一使用文档目录。
  Future<String> getJiebaSegmentFileDirPath() async {
    late String dirPath;
    if (Platform.isWindows) {
      dirPath = Directory(Platform.resolvedExecutable).parent.path;
      if (!FileUtil.testWriteable(dirPath)) {
        dirPath = await _loadDocumentsPath();
      }
    } else {
      dirPath = await _loadDocumentsPath();
    }
    return '$dirPath/jieba'.normalizePath;
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
            throw StateError('Jieba worker is not initialized');
          }
          final mode = SegMode.values.byName(message[_keyMode] as String);
          final segmenter = JiebaSegmenter();
          final tokens = segmenter
              .process(message[_keyText] as String, mode)
              .map(
                (token) => [
                  token.word,
                  token.startOffset,
                  token.endOffset,
                ],
              )
              .toList(growable: false);
          mainSendPort.send({
            _keyRequestId: requestId,
            _keySuccess: true,
            _keyData: tokens,
          });
          break;
        default:
          throw UnsupportedError('Unknown Jieba worker operation: $operation');
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
