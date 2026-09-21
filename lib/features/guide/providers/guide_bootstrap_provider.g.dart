// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guide_bootstrap_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 组装引导流程的步骤清单与初始完成状态。
///
/// 启动流程完成后即可读取，用于判断是否需要展示引导页。

@ProviderFor(GuideBootstrapNotifier)
final guideBootstrapProvider = GuideBootstrapNotifierProvider._();

/// 组装引导流程的步骤清单与初始完成状态。
///
/// 启动流程完成后即可读取，用于判断是否需要展示引导页。
final class GuideBootstrapNotifierProvider
    extends $AsyncNotifierProvider<GuideBootstrapNotifier, GuideBootstrap> {
  /// 组装引导流程的步骤清单与初始完成状态。
  ///
  /// 启动流程完成后即可读取，用于判断是否需要展示引导页。
  GuideBootstrapNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guideBootstrapProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guideBootstrapNotifierHash();

  @$internal
  @override
  GuideBootstrapNotifier create() => GuideBootstrapNotifier();
}

String _$guideBootstrapNotifierHash() =>
    r'2ea6bec57246f0565a4205d1d163c6b5c6276928';

/// 组装引导流程的步骤清单与初始完成状态。
///
/// 启动流程完成后即可读取，用于判断是否需要展示引导页。

abstract class _$GuideBootstrapNotifier extends $AsyncNotifier<GuideBootstrap> {
  FutureOr<GuideBootstrap> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<GuideBootstrap>, GuideBootstrap>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GuideBootstrap>, GuideBootstrap>,
              AsyncValue<GuideBootstrap>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
