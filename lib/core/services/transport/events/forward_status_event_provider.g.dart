// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forward_status_event_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ForwardStatusEventNotifier)
final forwardStatusEventProvider = ForwardStatusEventNotifierProvider._();

final class ForwardStatusEventNotifierProvider
    extends
        $StreamNotifierProvider<
          ForwardStatusEventNotifier,
          ForwardServerStatus
        > {
  ForwardStatusEventNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'forwardStatusEventProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$forwardStatusEventNotifierHash();

  @$internal
  @override
  ForwardStatusEventNotifier create() => ForwardStatusEventNotifier();
}

String _$forwardStatusEventNotifierHash() =>
    r'9a51abd3fd7ae54a6ab141dca2e458ffde8c54fe';

abstract class _$ForwardStatusEventNotifier
    extends $StreamNotifier<ForwardServerStatus> {
  Stream<ForwardServerStatus> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ForwardServerStatus>, ForwardServerStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ForwardServerStatus>, ForwardServerStatus>,
              AsyncValue<ForwardServerStatus>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
