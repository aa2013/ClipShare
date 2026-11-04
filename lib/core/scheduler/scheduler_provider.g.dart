// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduler_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 全局调度器，其他 provider 按需注册/注销任务。
///
/// 依赖数据库读取状态表，需在启动流程中早于业务任务注册方预加载。

@ProviderFor(scheduler)
final schedulerProvider = SchedulerProvider._();

/// 全局调度器，其他 provider 按需注册/注销任务。
///
/// 依赖数据库读取状态表，需在启动流程中早于业务任务注册方预加载。

final class SchedulerProvider
    extends
        $FunctionalProvider<
          AsyncValue<Scheduler>,
          Scheduler,
          FutureOr<Scheduler>
        >
    with $FutureModifier<Scheduler>, $FutureProvider<Scheduler> {
  /// 全局调度器，其他 provider 按需注册/注销任务。
  ///
  /// 依赖数据库读取状态表，需在启动流程中早于业务任务注册方预加载。
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
