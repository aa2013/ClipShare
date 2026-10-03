// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guide_step_handler_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 按步骤标识提供对应的权限处理器。
///
/// 引导流程的状态查询与步骤内容共用同一份处理器来源，避免两侧各自构造导致
/// 判定对象与实际授权对象不一致。纯信息步骤（工作模式、完成页）没有权限诉求，
/// 返回 null 表示其完成状态不由权限决定。

@ProviderFor(guideStepHandler)
final guideStepHandlerProvider = GuideStepHandlerFamily._();

/// 按步骤标识提供对应的权限处理器。
///
/// 引导流程的状态查询与步骤内容共用同一份处理器来源，避免两侧各自构造导致
/// 判定对象与实际授权对象不一致。纯信息步骤（工作模式、完成页）没有权限诉求，
/// 返回 null 表示其完成状态不由权限决定。

final class GuideStepHandlerProvider
    extends
        $FunctionalProvider<
          AsyncValue<AbstractPermissionHandler?>,
          AbstractPermissionHandler?,
          FutureOr<AbstractPermissionHandler?>
        >
    with
        $FutureModifier<AbstractPermissionHandler?>,
        $FutureProvider<AbstractPermissionHandler?> {
  /// 按步骤标识提供对应的权限处理器。
  ///
  /// 引导流程的状态查询与步骤内容共用同一份处理器来源，避免两侧各自构造导致
  /// 判定对象与实际授权对象不一致。纯信息步骤（工作模式、完成页）没有权限诉求，
  /// 返回 null 表示其完成状态不由权限决定。
  GuideStepHandlerProvider._({
    required GuideStepHandlerFamily super.from,
    required GuideStep super.argument,
  }) : super(
         retry: null,
         name: r'guideStepHandlerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$guideStepHandlerHash();

  @override
  String toString() {
    return r'guideStepHandlerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<AbstractPermissionHandler?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AbstractPermissionHandler?> create(Ref ref) {
    final argument = this.argument as GuideStep;
    return guideStepHandler(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GuideStepHandlerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$guideStepHandlerHash() => r'ceb94567ab7af1c02ec63e98871e2c7a7c3f7ed0';

/// 按步骤标识提供对应的权限处理器。
///
/// 引导流程的状态查询与步骤内容共用同一份处理器来源，避免两侧各自构造导致
/// 判定对象与实际授权对象不一致。纯信息步骤（工作模式、完成页）没有权限诉求，
/// 返回 null 表示其完成状态不由权限决定。

final class GuideStepHandlerFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<AbstractPermissionHandler?>,
          GuideStep
        > {
  GuideStepHandlerFamily._()
    : super(
        retry: null,
        name: r'guideStepHandlerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// 按步骤标识提供对应的权限处理器。
  ///
  /// 引导流程的状态查询与步骤内容共用同一份处理器来源，避免两侧各自构造导致
  /// 判定对象与实际授权对象不一致。纯信息步骤（工作模式、完成页）没有权限诉求，
  /// 返回 null 表示其完成状态不由权限决定。

  GuideStepHandlerProvider call(GuideStep id) =>
      GuideStepHandlerProvider._(argument: id, from: this);

  @override
  String toString() => r'guideStepHandlerProvider';
}
