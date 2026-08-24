// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rules_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RulesExecutorNotifier)
final rulesExecutorProvider = RulesExecutorNotifierProvider._();

final class RulesExecutorNotifierProvider
    extends $AsyncNotifierProvider<RulesExecutorNotifier, RuleState> {
  RulesExecutorNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rulesExecutorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rulesExecutorNotifierHash();

  @$internal
  @override
  RulesExecutorNotifier create() => RulesExecutorNotifier();
}

String _$rulesExecutorNotifierHash() =>
    r'c8ffd2c632d2929068df0b58b2cc4b18e264ef52';

abstract class _$RulesExecutorNotifier extends $AsyncNotifier<RuleState> {
  FutureOr<RuleState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<RuleState>, RuleState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<RuleState>, RuleState>,
              AsyncValue<RuleState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
