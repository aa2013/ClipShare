// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 日志文件列表控制器。
///
/// 文件来自应用配置的日志目录，列表按文件名倒序排列，保证最新的日志在最前。

@ProviderFor(LogsNotifier)
final logsProvider = LogsNotifierProvider._();

/// 日志文件列表控制器。
///
/// 文件来自应用配置的日志目录，列表按文件名倒序排列，保证最新的日志在最前。
final class LogsNotifierProvider
    extends $AsyncNotifierProvider<LogsNotifier, List<File>> {
  /// 日志文件列表控制器。
  ///
  /// 文件来自应用配置的日志目录，列表按文件名倒序排列，保证最新的日志在最前。
  LogsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'logsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$logsNotifierHash();

  @$internal
  @override
  LogsNotifier create() => LogsNotifier();
}

String _$logsNotifierHash() => r'1eb3c5adb78425ab820f960b13d8f5622de929e7';

/// 日志文件列表控制器。
///
/// 文件来自应用配置的日志目录，列表按文件名倒序排列，保证最新的日志在最前。

abstract class _$LogsNotifier extends $AsyncNotifier<List<File>> {
  FutureOr<List<File>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<File>>, List<File>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<File>>, List<File>>,
              AsyncValue<List<File>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 读取指定路径的日志文件内容。
///
/// 使用 [Utf8Decoder.allowMalformed] 容错解码，避免日志中的异常字节导致详情页无法打开。

@ProviderFor(logContent)
final logContentProvider = LogContentFamily._();

/// 读取指定路径的日志文件内容。
///
/// 使用 [Utf8Decoder.allowMalformed] 容错解码，避免日志中的异常字节导致详情页无法打开。

final class LogContentProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// 读取指定路径的日志文件内容。
  ///
  /// 使用 [Utf8Decoder.allowMalformed] 容错解码，避免日志中的异常字节导致详情页无法打开。
  LogContentProvider._({
    required LogContentFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'logContentProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$logContentHash();

  @override
  String toString() {
    return r'logContentProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as String;
    return logContent(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LogContentProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$logContentHash() => r'15fce47bfea212622d2b6df6f37dce32bbc7e704';

/// 读取指定路径的日志文件内容。
///
/// 使用 [Utf8Decoder.allowMalformed] 容错解码，避免日志中的异常字节导致详情页无法打开。

final class LogContentFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  LogContentFamily._()
    : super(
        retry: null,
        name: r'logContentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 读取指定路径的日志文件内容。
  ///
  /// 使用 [Utf8Decoder.allowMalformed] 容错解码，避免日志中的异常字节导致详情页无法打开。

  LogContentProvider call(String path) =>
      LogContentProvider._(argument: path, from: this);

  @override
  String toString() => r'logContentProvider';
}
