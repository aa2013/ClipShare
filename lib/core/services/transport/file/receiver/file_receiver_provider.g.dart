// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_receiver_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 文件接收器：统一处理直连、中转、存储中转三条通道的接收落盘、
/// 进度上报与完成收尾（历史记录、系统通知、媒体库扫描）。

@ProviderFor(FileReceiverNotifier)
final fileReceiverProvider = FileReceiverNotifierProvider._();

/// 文件接收器：统一处理直连、中转、存储中转三条通道的接收落盘、
/// 进度上报与完成收尾（历史记录、系统通知、媒体库扫描）。
final class FileReceiverNotifierProvider
    extends $NotifierProvider<FileReceiverNotifier, void> {
  /// 文件接收器：统一处理直连、中转、存储中转三条通道的接收落盘、
  /// 进度上报与完成收尾（历史记录、系统通知、媒体库扫描）。
  FileReceiverNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileReceiverProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileReceiverNotifierHash();

  @$internal
  @override
  FileReceiverNotifier create() => FileReceiverNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$fileReceiverNotifierHash() =>
    r'ce51af207bbdd74a134d4ad3ea7489954dd4ef05';

/// 文件接收器：统一处理直连、中转、存储中转三条通道的接收落盘、
/// 进度上报与完成收尾（历史记录、系统通知、媒体库扫描）。

abstract class _$FileReceiverNotifier extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
