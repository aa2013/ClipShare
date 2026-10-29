import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/settings/app_paths/custom_path_resolver.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database_provider.g.dart';

///打开应用数据库
///
///数据库文件路径由 [resolveDatabasePath] 从全局 [customPathConfig]（main 在 runApp 前初始化）与平台目录解析而来
@Riverpod(keepAlive: true)
Future<AppDatabase> appDb(Ref ref) async {
  final documentsPath = await initDocumentsPath();
  final databasePath = await resolveDatabasePath(
    customPathConfig,
    documentsPath,
  );
  final executor = await AppDatabase.openFile(databasePath);
  final db = AppDatabase(executor);
  ref.onDispose(db.close);
  return db;
}
