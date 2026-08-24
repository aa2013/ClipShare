// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'id_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(id)
final idProvider = IdProvider._();

final class IdProvider
    extends $FunctionalProvider<Snowflake, Snowflake, Snowflake>
    with $Provider<Snowflake> {
  IdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'idProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$idHash();

  @$internal
  @override
  $ProviderElement<Snowflake> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Snowflake create(Ref ref) {
    return id(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Snowflake value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Snowflake>(value),
    );
  }
}

String _$idHash() => r'b7bd0745471376319b5fa9c8f1e711a7b628ea70';
