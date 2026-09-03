import 'package:clipshare/core/providers/settings/app_paths/app_paths_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'jieba_segment_service.dart';

part 'jieba_segment_provider.g.dart';

/// 全局唯一的分词服务实例。
///
/// keepAlive 保证 isolate 常驻、词典只加载一次，避免每次打开分词页重复初始化。
@Riverpod(keepAlive: true)
JiebaSegmentService jiebaSegmentService(Ref ref) {
  final service = JiebaSegmentService(
    loadDocumentsPath: () async => (await ref.read(appPathsProvider.future)).documentsPath,
  );
  ref.onDispose(service.dispose);
  return service;
}
