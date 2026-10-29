// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rule_sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 规则同步处理器。

@ProviderFor(RuleSyncNotifier)
final ruleSyncProvider = RuleSyncNotifierProvider._();

/// 规则同步处理器。
final class RuleSyncNotifierProvider
    extends $NotifierProvider<RuleSyncNotifier, void> {
  /// 规则同步处理器。
  RuleSyncNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ruleSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ruleSyncNotifierHash();

  @$internal
  @override
  RuleSyncNotifier create() => RuleSyncNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$ruleSyncNotifierHash() => r'0b7a76d852a31faaffe765c8fbb24f47a5c8c515';

/// 规则同步处理器。

abstract class _$RuleSyncNotifier extends $Notifier<void> {
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
