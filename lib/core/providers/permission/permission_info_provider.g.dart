// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PermissionInfoNotifier)
final permissionInfoProvider = PermissionInfoNotifierProvider._();

final class PermissionInfoNotifierProvider
    extends $AsyncNotifierProvider<PermissionInfoNotifier, PermissionInfo> {
  PermissionInfoNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'permissionInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$permissionInfoNotifierHash();

  @$internal
  @override
  PermissionInfoNotifier create() => PermissionInfoNotifier();
}

String _$permissionInfoNotifierHash() =>
    r'baa1b5e36b110f9506c1a25f6130779a53c12782';

abstract class _$PermissionInfoNotifier extends $AsyncNotifier<PermissionInfo> {
  FutureOr<PermissionInfo> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PermissionInfo>, PermissionInfo>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PermissionInfo>, PermissionInfo>,
              AsyncValue<PermissionInfo>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
