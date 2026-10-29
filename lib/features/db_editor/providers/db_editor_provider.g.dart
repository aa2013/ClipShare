// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_editor_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 数据库编辑页状态管理：执行 SQL、维护查询结果并持久化最近编辑内容。

@ProviderFor(DbEditorNotifier)
final dbEditorProvider = DbEditorNotifierProvider._();

/// 数据库编辑页状态管理：执行 SQL、维护查询结果并持久化最近编辑内容。
final class DbEditorNotifierProvider
    extends $NotifierProvider<DbEditorNotifier, DbEditorState> {
  /// 数据库编辑页状态管理：执行 SQL、维护查询结果并持久化最近编辑内容。
  DbEditorNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dbEditorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dbEditorNotifierHash();

  @$internal
  @override
  DbEditorNotifier create() => DbEditorNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DbEditorState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DbEditorState>(value),
    );
  }
}

String _$dbEditorNotifierHash() => r'bb2c0b572af7aa92cc23d9f97809b7f99563c705';

/// 数据库编辑页状态管理：执行 SQL、维护查询结果并持久化最近编辑内容。

abstract class _$DbEditorNotifier extends $Notifier<DbEditorState> {
  DbEditorState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DbEditorState, DbEditorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DbEditorState, DbEditorState>,
              DbEditorState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
