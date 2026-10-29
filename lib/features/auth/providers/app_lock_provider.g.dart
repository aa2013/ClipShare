// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_lock_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 应用锁调度器：
/// * 打开验证页（启动锁、超时/亮屏重验、设置页前置验证）
/// * 监听应用生命周期，回到前台超过配置时长时触发重验
/// * 订阅 Android 亮屏事件触发重验
/// * 移动端随安全配置同步防截屏状态

@ProviderFor(AppLockNotifier)
final appLockProvider = AppLockNotifierProvider._();

/// 应用锁调度器：
/// * 打开验证页（启动锁、超时/亮屏重验、设置页前置验证）
/// * 监听应用生命周期，回到前台超过配置时长时触发重验
/// * 订阅 Android 亮屏事件触发重验
/// * 移动端随安全配置同步防截屏状态
final class AppLockNotifierProvider
    extends $NotifierProvider<AppLockNotifier, void> {
  /// 应用锁调度器：
  /// * 打开验证页（启动锁、超时/亮屏重验、设置页前置验证）
  /// * 监听应用生命周期，回到前台超过配置时长时触发重验
  /// * 订阅 Android 亮屏事件触发重验
  /// * 移动端随安全配置同步防截屏状态
  AppLockNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLockNotifierHash();

  @$internal
  @override
  AppLockNotifier create() => AppLockNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$appLockNotifierHash() => r'020c3a1761c3ea74796089cde4e22442b7559c8a';

/// 应用锁调度器：
/// * 打开验证页（启动锁、超时/亮屏重验、设置页前置验证）
/// * 监听应用生命周期，回到前台超过配置时长时触发重验
/// * 订阅 Android 亮屏事件触发重验
/// * 移动端随安全配置同步防截屏状态

abstract class _$AppLockNotifier extends $Notifier<void> {
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
