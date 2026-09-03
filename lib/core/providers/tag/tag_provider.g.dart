// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TagNotifier)
final tagProvider = TagNotifierProvider._();

final class TagNotifierProvider
    extends $AsyncNotifierProvider<TagNotifier, TagState> {
  TagNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagNotifierHash();

  @$internal
  @override
  TagNotifier create() => TagNotifier();
}

String _$tagNotifierHash() => r'30cafbd23186ec24fff8fc71e6bd6d8135d4e56c';

abstract class _$TagNotifier extends $AsyncNotifier<TagState> {
  FutureOr<TagState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TagState>, TagState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TagState>, TagState>,
              AsyncValue<TagState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
