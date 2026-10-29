// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hot_key_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HotKeyNotifier)
final hotKeyProvider = HotKeyNotifierProvider._();

final class HotKeyNotifierProvider
    extends $AsyncNotifierProvider<HotKeyNotifier, Map<HotKeyType, HotKey>> {
  HotKeyNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hotKeyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hotKeyNotifierHash();

  @$internal
  @override
  HotKeyNotifier create() => HotKeyNotifier();
}

String _$hotKeyNotifierHash() => r'fc7760571a103eaaccabf2f3aa8c2e542ea0452d';

abstract class _$HotKeyNotifier
    extends $AsyncNotifier<Map<HotKeyType, HotKey>> {
  FutureOr<Map<HotKeyType, HotKey>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<HotKeyType, HotKey>>,
              Map<HotKeyType, HotKey>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<HotKeyType, HotKey>>,
                Map<HotKeyType, HotKey>
              >,
              AsyncValue<Map<HotKeyType, HotKey>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
