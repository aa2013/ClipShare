// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operation_record_cleanup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 操作记录级联清理

@ProviderFor(OperationRecordCleanup)
final operationRecordCleanupProvider = OperationRecordCleanupProvider._();

/// 操作记录级联清理
final class OperationRecordCleanupProvider
    extends $NotifierProvider<OperationRecordCleanup, void> {
  /// 操作记录级联清理
  OperationRecordCleanupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'operationRecordCleanupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$operationRecordCleanupHash();

  @$internal
  @override
  OperationRecordCleanup create() => OperationRecordCleanup();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$operationRecordCleanupHash() =>
    r'3b9568a1ef775b51fcd5aeb0fc36c6f7f5d7a1b6';

/// 操作记录级联清理

abstract class _$OperationRecordCleanup extends $Notifier<void> {
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
