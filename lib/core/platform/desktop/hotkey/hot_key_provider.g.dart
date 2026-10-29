// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hot_key_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 全局热键服务。
///
/// 职责：系统级热键的注册/注销与按下处理；启动时确保 Win+V 接管状态
/// 与注册表一致并按配置注册热键；退出前释放全部热键并按设置恢复 Win+V。

@ProviderFor(HotKeyNotifier)
final hotKeyProvider = HotKeyNotifierProvider._();

/// 全局热键服务。
///
/// 职责：系统级热键的注册/注销与按下处理；启动时确保 Win+V 接管状态
/// 与注册表一致并按配置注册热键；退出前释放全部热键并按设置恢复 Win+V。
final class HotKeyNotifierProvider
    extends $AsyncNotifierProvider<HotKeyNotifier, void> {
  /// 全局热键服务。
  ///
  /// 职责：系统级热键的注册/注销与按下处理；启动时确保 Win+V 接管状态
  /// 与注册表一致并按配置注册热键；退出前释放全部热键并按设置恢复 Win+V。
  HotKeyNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hotKeyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hotKeyNotifierHash();

  @$internal
  @override
  HotKeyNotifier create() => HotKeyNotifier();
}

String _$hotKeyNotifierHash() => r'9ceacb45ad833a616bc218d46be30b1866469e43';

/// 全局热键服务。
///
/// 职责：系统级热键的注册/注销与按下处理；启动时确保 Win+V 接管状态
/// 与注册表一致并按配置注册热键；退出前释放全部热键并按设置恢复 Win+V。

abstract class _$HotKeyNotifier extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
