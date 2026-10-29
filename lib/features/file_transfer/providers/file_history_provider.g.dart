// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 文件历史列表：加载本机历史发送/接收的文件记录，
/// 订阅历史增量事件，文件类型记录增删时自动重载。

@ProviderFor(FileHistoryNotifier)
final fileHistoryProvider = FileHistoryNotifierProvider._();

/// 文件历史列表：加载本机历史发送/接收的文件记录，
/// 订阅历史增量事件，文件类型记录增删时自动重载。
final class FileHistoryNotifierProvider
    extends $AsyncNotifierProvider<FileHistoryNotifier, FileHistoryList> {
  /// 文件历史列表：加载本机历史发送/接收的文件记录，
  /// 订阅历史增量事件，文件类型记录增删时自动重载。
  FileHistoryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileHistoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileHistoryNotifierHash();

  @$internal
  @override
  FileHistoryNotifier create() => FileHistoryNotifier();
}

String _$fileHistoryNotifierHash() =>
    r'3cbc662a6ee482115811ccbc07f59bdd88acbd85';

/// 文件历史列表：加载本机历史发送/接收的文件记录，
/// 订阅历史增量事件，文件类型记录增删时自动重载。

abstract class _$FileHistoryNotifier extends $AsyncNotifier<FileHistoryList> {
  FutureOr<FileHistoryList> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<FileHistoryList>, FileHistoryList>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<FileHistoryList>, FileHistoryList>,
              AsyncValue<FileHistoryList>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
