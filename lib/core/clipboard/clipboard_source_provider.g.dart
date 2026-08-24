// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clipboard_source_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ClipboardSourceNotifier)
final clipboardSourceProvider = ClipboardSourceNotifierProvider._();

final class ClipboardSourceNotifierProvider
    extends
        $AsyncNotifierProvider<ClipboardSourceNotifier, ClipboardSourceState> {
  ClipboardSourceNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clipboardSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clipboardSourceNotifierHash();

  @$internal
  @override
  ClipboardSourceNotifier create() => ClipboardSourceNotifier();
}

String _$clipboardSourceNotifierHash() =>
    r'7d29bfed43da24cd07249875875029c09a7f0204';

abstract class _$ClipboardSourceNotifier
    extends $AsyncNotifier<ClipboardSourceState> {
  FutureOr<ClipboardSourceState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<ClipboardSourceState>, ClipboardSourceState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ClipboardSourceState>,
                ClipboardSourceState
              >,
              AsyncValue<ClipboardSourceState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
