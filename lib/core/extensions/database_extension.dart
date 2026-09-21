import 'package:clipshare/core/database/app_database.dart';
import 'package:clipshare/shared/utils/log.dart';

extension AppDatabaseExt on AppDatabase {
  static Future _queue = Future.value();
  static const _tag = 'AppDatabaseExt';

  void execSequentially(Future Function() f) {
    _queue = _queue.whenComplete(() => f().catchError((err, stack) => logger.error(_tag, err, stack)));
  }

  Future<List<Map<String, Object?>>> rawQuery(String sql) {
    return executor.runSelect(sql, const []);
  }
}
