// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_recorder_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HistoryRecorderNotifier)
final historyRecorderProvider = HistoryRecorderNotifierProvider._();

final class HistoryRecorderNotifierProvider
    extends $AsyncNotifierProvider<HistoryRecorderNotifier, void> {
  HistoryRecorderNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyRecorderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyRecorderNotifierHash();

  @$internal
  @override
  HistoryRecorderNotifier create() => HistoryRecorderNotifier();
}

String _$historyRecorderNotifierHash() =>
    r'6b4f3a6a608a8f8e5ae1b05feba9642436bbeb34';

abstract class _$HistoryRecorderNotifier extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
