import 'package:clipshare/core/database/app_database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'data_cleanup_config.dart';

part 'data_cleanup_config_provider.g.dart';

/// 读取数据清理配置
@Riverpod(keepAlive: true)
class DataCleanupConfigNotifier extends _$DataCleanupConfigNotifier {
  @override
  Future<DataCleanupConfig?> build() async {
    final cfg = (await ref.read(appDbProvider.future)).configDao;
    return cfg.getConfigByKey(.cleanDataConfig, null, convert: DataCleanupConfig.tryParse);
  }
}
