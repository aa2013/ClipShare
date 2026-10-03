// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guide_controller_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 引导流程控制。
///
/// 只维护「当前步骤」与「各步骤完成状态」；翻页动画与路由跳转属于页面职责，
/// 不放进状态，避免 UI 对象跟随 provider 生命周期存活。

@ProviderFor(GuideController)
final guideControllerProvider = GuideControllerProvider._();

/// 引导流程控制。
///
/// 只维护「当前步骤」与「各步骤完成状态」；翻页动画与路由跳转属于页面职责，
/// 不放进状态，避免 UI 对象跟随 provider 生命周期存活。
final class GuideControllerProvider
    extends $NotifierProvider<GuideController, GuideState> {
  /// 引导流程控制。
  ///
  /// 只维护「当前步骤」与「各步骤完成状态」；翻页动画与路由跳转属于页面职责，
  /// 不放进状态，避免 UI 对象跟随 provider 生命周期存活。
  GuideControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guideControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guideControllerHash();

  @$internal
  @override
  GuideController create() => GuideController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GuideState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GuideState>(value),
    );
  }
}

String _$guideControllerHash() => r'7c939228d9b29ce915d190bd8300e94a0d06fd1e';

/// 引导流程控制。
///
/// 只维护「当前步骤」与「各步骤完成状态」；翻页动画与路由跳转属于页面职责，
/// 不放进状态，避免 UI 对象跟随 provider 生命周期存活。

abstract class _$GuideController extends $Notifier<GuideState> {
  GuideState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<GuideState, GuideState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GuideState, GuideState>,
              GuideState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
