import 'dart:async';

import 'package:clipshare/shared/utils/parallerl_task.dart';

/// 泛型流的取消扩展：令牌触发时让输出流立即结束，
/// 使消费该流的下游请求（socket 写入、HTTP 上传）随之中断。
extension CancellableStreamExt<T> on Stream<T> {
  /// 返回在 [cancelToken] 触发时立即以 [cancelError] 结束的流。
  ///
  /// 取消不依赖新的数据事件：令牌触发即取消源订阅并结束输出流，
  /// 因此上游因背压暂停供数时下游也能立刻收到错误。
  /// pause/resume/cancel 均转发给源订阅，保留原有背压与资源释放时机。
  /// [cancelToken] 为空时原样返回，不做包装。
  Stream<T> cancellable(
    CancelToken? cancelToken, {
    required Object Function() cancelError,
  }) {
    if (cancelToken == null) {
      return this;
    }
    StreamSubscription<T>? subscription;
    CancelTokenRegistration? registration;
    late final StreamController<T> controller;

    /// 结束输出流；已结束时直接返回，避免关闭后重复关闭。
    void closeOutput() {
      if (controller.isClosed) {
        return;
      }
      unawaited(controller.close());
    }

    /// 令牌触发：先断开源订阅停止继续供数，再让输出流以取消错误结束。
    void onCanceled() {
      unawaited(subscription?.cancel());
      if (controller.isClosed) {
        return;
      }
      controller.addError(cancelError());
      closeOutput();
    }

    controller = StreamController<T>(
      onListen: () {
        subscription = listen(
          controller.add,
          onError: controller.addError,
          onDone: () {
            registration?.dispose();
            closeOutput();
          },
        );
        registration = cancelToken.register(onCanceled);
        // 源流可能在订阅期间同步结束，此时不必再持有取消注册
        if (controller.isClosed) {
          registration?.dispose();
        }
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () {
        registration?.dispose();
        return subscription?.cancel();
      },
    );
    return controller.stream;
  }
}

/// 泛型 Future 的取消扩展：令牌触发时让等待方立即收口。
extension CancellableFutureExt<T> on Future<T> {
  /// 等待该 Future，但 [cancelToken] 触发时立即以 [cancelError] 抛出。
  ///
  /// 只让等待方立即收口，并不会中断该 Future 本身；
  /// 其最终结果由 [Future.any] 吸收，不会成为未捕获异常。
  Future<T> orCancel(
    CancelToken cancelToken, {
    required Object Function() cancelError,
  }) async {
    if (cancelToken.isCanceled) {
      throw cancelError();
    }
    final canceled = Completer<void>();
    final registration = cancelToken.register(() {
      if (!canceled.isCompleted) {
        canceled.complete();
      }
    });
    try {
      return await Future.any<T>([
        this,
        canceled.future.then<T>((_) => throw cancelError()),
      ]);
    } finally {
      registration.dispose();
    }
  }
}
