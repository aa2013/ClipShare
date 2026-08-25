import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/core/providers/settings/app_paths/app_paths_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database_provider.g.dart';

@Riverpod(keepAlive: true)
Future<AppDatabase> appDb(Ref ref) async {
  final appPaths = await ref.read(appPathsProvider.future);
  final executor = await AppDatabase.openFile(appPaths.databasePath);
  final db = AppDatabase(executor);
  ref.onDispose(db.close);
  return db;
}