import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:clipshare/core/database/dao/config_dao.dart';
import 'package:clipshare/core/extensions/database_extension.dart';
import 'package:clipshare/core/settings/preference/preference_settings_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'db_editor_provider.g.dart';

/// 数据库编辑页状态：查询结果保存原始行数据，结果表格由页面负责构建。
class DbEditorState {
  final bool loading;
  final List<Map<String, Object?>> results;

  /// 执行无 limit 的 select 语句前是否弹出确认提示
  final bool showLimitTips;

  const DbEditorState({
    this.loading = false,
    this.results = const [],
    this.showLimitTips = true,
  });

  DbEditorState copyWith({
    bool? loading,
    List<Map<String, Object?>>? results,
    bool? showLimitTips,
  }) {
    return DbEditorState(
      loading: loading ?? this.loading,
      results: results ?? this.results,
      showLimitTips: showLimitTips ?? this.showLimitTips,
    );
  }
}

/// 数据库编辑页状态管理：执行 SQL、维护查询结果并持久化最近编辑内容。
@riverpod
class DbEditorNotifier extends _$DbEditorNotifier {
  AppDatabase get _db => ref.read(appDbProvider).requireValue;

  ConfigDao get _configDao => _db.configDao;

  @override
  DbEditorState build() {
    return const DbEditorState();
  }

  /// 切换无 limit 的 select 语句执行前确认提示。
  void toggleLimitCheck() {
    state = state.copyWith(showLimitTips: !state.showLimitTips);
  }

  /// 执行 [sql] 并将其保存为最近编辑内容；查询异常向上抛出，由页面弹窗展示。
  Future<void> exec(String sql) async {
    //依赖在首个 await 前取出，避免异步途中 provider 被销毁
    final db = _db;
    final configDao = _configDao;
    state = state.copyWith(loading: true, results: const []);
    try {
      final results = await db.rawQuery(sql);
      await configDao.addOrUpdate(.lastSqlEditContent, sql);
      ref.invalidate(preferenceSettingsProvider);
      state = state.copyWith(loading: false, results: results);
    } catch (_) {
      state = state.copyWith(loading: false);
      rethrow;
    }
  }
}
