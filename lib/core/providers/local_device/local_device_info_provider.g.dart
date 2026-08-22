// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_device_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(localDeviceInfo)
final localDeviceInfoProvider = LocalDeviceInfoProvider._();

final class LocalDeviceInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<LocalDeviceInfo>,
          LocalDeviceInfo,
          FutureOr<LocalDeviceInfo>
        >
    with $FutureModifier<LocalDeviceInfo>, $FutureProvider<LocalDeviceInfo> {
  LocalDeviceInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localDeviceInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localDeviceInfoHash();

  @$internal
  @override
  $FutureProviderElement<LocalDeviceInfo> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LocalDeviceInfo> create(Ref ref) {
    return localDeviceInfo(ref);
  }
}

String _$localDeviceInfoHash() => r'336d74d5976ec3f38b3c1120f3b4e60916090995';
