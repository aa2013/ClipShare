// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduler_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 全局调度器，其他 provider 按需注册/注销任务

@ProviderFor(scheduler)
final schedulerProvider = SchedulerProvider._();

/// 全局调度器，其他 provider 按需注册/注销任务

final class SchedulerProvider
    extends
        $FunctionalProvider<
          AsyncValue<Scheduler>,
          Scheduler,
          FutureOr<Scheduler>
        >
    with $FutureModifier<Scheduler>, $FutureProvider<Scheduler> {
  /// 全局调度器，其他 provider 按需注册/注销任务
  SchedulerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'schedulerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$schedulerHash();

  @$internal
  @override
  $FutureProviderElement<Scheduler> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Scheduler> create(Ref ref) {
    return scheduler(ref);
  }
}

String _$schedulerHash() => r'0f712156b7e068be8fc6b667fab7d06104691279';

/// App 内固定定时任务的统一注册入口。
///
/// 等 UI 就绪（[AppInitStatus.uiReady]）后再注册，保证任务首次执行时页面、弹窗与导航栈已可用；
/// 任务释放由 [SchedulerImpl.dispose] 统一完成，此处无需额外的注销处理。

@ProviderFor(schedulerRegistry)
final schedulerRegistryProvider = SchedulerRegistryProvider._();

/// App 内固定定时任务的统一注册入口。
///
/// 等 UI 就绪（[AppInitStatus.uiReady]）后再注册，保证任务首次执行时页面、弹窗与导航栈已可用；
/// 任务释放由 [SchedulerImpl.dispose] 统一完成，此处无需额外的注销处理。

final class SchedulerRegistryProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// App 内固定定时任务的统一注册入口。
  ///
  /// 等 UI 就绪（[AppInitStatus.uiReady]）后再注册，保证任务首次执行时页面、弹窗与导航栈已可用；
  /// 任务释放由 [SchedulerImpl.dispose] 统一完成，此处无需额外的注销处理。
  SchedulerRegistryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'schedulerRegistryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$schedulerRegistryHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return schedulerRegistry(ref);
  }
}

String _$schedulerRegistryHash() => r'f56d5e1527e90ed3eecd3fd00b19f29310b9bd31';
