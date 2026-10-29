// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_transfer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 文件传输状态中枢：持有发送队列与全部收发任务，按设备串行调度发送。
/// state 为任务快照，UI 直接 watch 展示队列与进度。

@ProviderFor(FileTransferNotifier)
final fileTransferProvider = FileTransferNotifierProvider._();

/// 文件传输状态中枢：持有发送队列与全部收发任务，按设备串行调度发送。
/// state 为任务快照，UI 直接 watch 展示队列与进度。
final class FileTransferNotifierProvider
    extends $NotifierProvider<FileTransferNotifier, List<FileTransferTask>> {
  /// 文件传输状态中枢：持有发送队列与全部收发任务，按设备串行调度发送。
  /// state 为任务快照，UI 直接 watch 展示队列与进度。
  FileTransferNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileTransferProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileTransferNotifierHash();

  @$internal
  @override
  FileTransferNotifier create() => FileTransferNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FileTransferTask> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FileTransferTask>>(value),
    );
  }
}

String _$fileTransferNotifierHash() =>
    r'823f3e18fd47dc74b74cc3fdb9ed4f104093f017';

/// 文件传输状态中枢：持有发送队列与全部收发任务，按设备串行调度发送。
/// state 为任务快照，UI 直接 watch 展示队列与进度。

abstract class _$FileTransferNotifier
    extends $Notifier<List<FileTransferTask>> {
  List<FileTransferTask> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<List<FileTransferTask>, List<FileTransferTask>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<FileTransferTask>, List<FileTransferTask>>,
              List<FileTransferTask>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
