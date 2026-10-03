// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'android_environment_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Android 剪贴板工作环境状态。
///
/// 状态由「工作模式配置 + 特权环境授权 + 监听服务是否就绪」三者共同决定，
/// 三个来源都会在运行期变化：工作模式配置变化时本 provider 自动重建，
/// 从系统授权页返回、Shizuku 断开等场景由 [refresh] 复查。

@ProviderFor(AndroidEnvironmentStatusNotifier)
final androidEnvironmentStatusProvider =
    AndroidEnvironmentStatusNotifierProvider._();

/// Android 剪贴板工作环境状态。
///
/// 状态由「工作模式配置 + 特权环境授权 + 监听服务是否就绪」三者共同决定，
/// 三个来源都会在运行期变化：工作模式配置变化时本 provider 自动重建，
/// 从系统授权页返回、Shizuku 断开等场景由 [refresh] 复查。
final class AndroidEnvironmentStatusNotifierProvider
    extends
        $AsyncNotifierProvider<
          AndroidEnvironmentStatusNotifier,
          AndroidEnvironmentStatus
        > {
  /// Android 剪贴板工作环境状态。
  ///
  /// 状态由「工作模式配置 + 特权环境授权 + 监听服务是否就绪」三者共同决定，
  /// 三个来源都会在运行期变化：工作模式配置变化时本 provider 自动重建，
  /// 从系统授权页返回、Shizuku 断开等场景由 [refresh] 复查。
  AndroidEnvironmentStatusNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'androidEnvironmentStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$androidEnvironmentStatusNotifierHash();

  @$internal
  @override
  AndroidEnvironmentStatusNotifier create() =>
      AndroidEnvironmentStatusNotifier();
}

String _$androidEnvironmentStatusNotifierHash() =>
    r'3ca99303d11bb1c13acc9980d10b773863ab75b5';

/// Android 剪贴板工作环境状态。
///
/// 状态由「工作模式配置 + 特权环境授权 + 监听服务是否就绪」三者共同决定，
/// 三个来源都会在运行期变化：工作模式配置变化时本 provider 自动重建，
/// 从系统授权页返回、Shizuku 断开等场景由 [refresh] 复查。

abstract class _$AndroidEnvironmentStatusNotifier
    extends $AsyncNotifier<AndroidEnvironmentStatus> {
  FutureOr<AndroidEnvironmentStatus> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<AndroidEnvironmentStatus>,
              AndroidEnvironmentStatus
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<AndroidEnvironmentStatus>,
                AndroidEnvironmentStatus
              >,
              AsyncValue<AndroidEnvironmentStatus>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
