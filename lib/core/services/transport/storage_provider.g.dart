// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 结构：
/// history
/// - A
///   - 2025-09-08
///     - files
///       - 1321546
///       - filename
///     13215478545
///   - 2025-09-07
///     - files
///       - 1321546
///       - filename
///     1654646544
/// devices-info
/// - A
///   - deviceInfo.json
///   - minVersion.json
///   - version.json
/// - B
///   - deviceInfo.json
///   - minVersion.json
///   - version.json
/// app-info
/// - A
///  - 1321465456444
/// 监听网络恢复

@ProviderFor(StorageNotifier)
final storageProvider = StorageNotifierProvider._();

/// 结构：
/// history
/// - A
///   - 2025-09-08
///     - files
///       - 1321546
///       - filename
///     13215478545
///   - 2025-09-07
///     - files
///       - 1321546
///       - filename
///     1654646544
/// devices-info
/// - A
///   - deviceInfo.json
///   - minVersion.json
///   - version.json
/// - B
///   - deviceInfo.json
///   - minVersion.json
///   - version.json
/// app-info
/// - A
///  - 1321465456444
/// 监听网络恢复
final class StorageNotifierProvider
    extends $NotifierProvider<StorageNotifier, void> {
  /// 结构：
  /// history
  /// - A
  ///   - 2025-09-08
  ///     - files
  ///       - 1321546
  ///       - filename
  ///     13215478545
  ///   - 2025-09-07
  ///     - files
  ///       - 1321546
  ///       - filename
  ///     1654646544
  /// devices-info
  /// - A
  ///   - deviceInfo.json
  ///   - minVersion.json
  ///   - version.json
  /// - B
  ///   - deviceInfo.json
  ///   - minVersion.json
  ///   - version.json
  /// app-info
  /// - A
  ///  - 1321465456444
  /// 监听网络恢复
  StorageNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageNotifierHash();

  @$internal
  @override
  StorageNotifier create() => StorageNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$storageNotifierHash() => r'0f390884b76ad3f16067551a429e1e7f1dbbd9b1';

/// 结构：
/// history
/// - A
///   - 2025-09-08
///     - files
///       - 1321546
///       - filename
///     13215478545
///   - 2025-09-07
///     - files
///       - 1321546
///       - filename
///     1654646544
/// devices-info
/// - A
///   - deviceInfo.json
///   - minVersion.json
///   - version.json
/// - B
///   - deviceInfo.json
///   - minVersion.json
///   - version.json
/// app-info
/// - A
///  - 1321465456444
/// 监听网络恢复

abstract class _$StorageNotifier extends $Notifier<void> {
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
