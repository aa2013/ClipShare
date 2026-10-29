// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 标签同步处理器。

@ProviderFor(TagSyncNotifier)
final tagSyncProvider = TagSyncNotifierProvider._();

/// 标签同步处理器。
final class TagSyncNotifierProvider
    extends $NotifierProvider<TagSyncNotifier, void> {
  /// 标签同步处理器。
  TagSyncNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagSyncNotifierHash();

  @$internal
  @override
  TagSyncNotifier create() => TagSyncNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$tagSyncNotifierHash() => r'45997c7b8e4fe98613049ba63db85e91f884319b';

/// 标签同步处理器。

abstract class _$TagSyncNotifier extends $Notifier<void> {
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
