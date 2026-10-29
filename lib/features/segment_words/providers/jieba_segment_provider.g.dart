// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jieba_segment_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 全局唯一的分词服务实例。
///
/// keepAlive 保证 isolate 常驻、词典只加载一次，避免每次打开分词页重复初始化。

@ProviderFor(jiebaSegmentService)
final jiebaSegmentServiceProvider = JiebaSegmentServiceProvider._();

/// 全局唯一的分词服务实例。
///
/// keepAlive 保证 isolate 常驻、词典只加载一次，避免每次打开分词页重复初始化。

final class JiebaSegmentServiceProvider
    extends
        $FunctionalProvider<
          JiebaSegmentService,
          JiebaSegmentService,
          JiebaSegmentService
        >
    with $Provider<JiebaSegmentService> {
  /// 全局唯一的分词服务实例。
  ///
  /// keepAlive 保证 isolate 常驻、词典只加载一次，避免每次打开分词页重复初始化。
  JiebaSegmentServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jiebaSegmentServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jiebaSegmentServiceHash();

  @$internal
  @override
  $ProviderElement<JiebaSegmentService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  JiebaSegmentService create(Ref ref) {
    return jiebaSegmentService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JiebaSegmentService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JiebaSegmentService>(value),
    );
  }
}

String _$jiebaSegmentServiceHash() =>
    r'15a9ffb223c32d78dfeddb5b11c53811eb743118';
