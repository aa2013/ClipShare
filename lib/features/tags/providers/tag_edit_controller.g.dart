// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_edit_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 标签编辑控制器，按历史记录 id 独立维护编辑态。
///
/// 采用 autoDispose：弹窗关闭或页面退出后自动销毁，下次打开天然重置。

@ProviderFor(TagEditController)
final tagEditControllerProvider = TagEditControllerFamily._();

/// 标签编辑控制器，按历史记录 id 独立维护编辑态。
///
/// 采用 autoDispose：弹窗关闭或页面退出后自动销毁，下次打开天然重置。
final class TagEditControllerProvider
    extends $AsyncNotifierProvider<TagEditController, TagEditState> {
  /// 标签编辑控制器，按历史记录 id 独立维护编辑态。
  ///
  /// 采用 autoDispose：弹窗关闭或页面退出后自动销毁，下次打开天然重置。
  TagEditControllerProvider._({
    required TagEditControllerFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'tagEditControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tagEditControllerHash();

  @override
  String toString() {
    return r'tagEditControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TagEditController create() => TagEditController();

  @override
  bool operator ==(Object other) {
    return other is TagEditControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tagEditControllerHash() => r'2fde7cb9a264a89440897c6a9cabe5bd129029ee';

/// 标签编辑控制器，按历史记录 id 独立维护编辑态。
///
/// 采用 autoDispose：弹窗关闭或页面退出后自动销毁，下次打开天然重置。

final class TagEditControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          TagEditController,
          AsyncValue<TagEditState>,
          TagEditState,
          FutureOr<TagEditState>,
          int
        > {
  TagEditControllerFamily._()
    : super(
        retry: null,
        name: r'tagEditControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 标签编辑控制器，按历史记录 id 独立维护编辑态。
  ///
  /// 采用 autoDispose：弹窗关闭或页面退出后自动销毁，下次打开天然重置。

  TagEditControllerProvider call(int hisId) =>
      TagEditControllerProvider._(argument: hisId, from: this);

  @override
  String toString() => r'tagEditControllerProvider';
}

/// 标签编辑控制器，按历史记录 id 独立维护编辑态。
///
/// 采用 autoDispose：弹窗关闭或页面退出后自动销毁，下次打开天然重置。

abstract class _$TagEditController extends $AsyncNotifier<TagEditState> {
  late final _$args = ref.$arg as int;
  int get hisId => _$args;

  FutureOr<TagEditState> build(int hisId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TagEditState>, TagEditState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TagEditState>, TagEditState>,
              AsyncValue<TagEditState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
