import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_page_index_provider.g.dart';

/// 文件传输页在首页 pages 中的固定位置
const fileTransferPageIndex = 2;

/// 首页当前页序，宽窄屏布局共用；供整窗拖拽等场景跨页跳转使用
@Riverpod(keepAlive: true)
class HomePageIndexNotifier extends _$HomePageIndexNotifier {
  @override
  int build() {
    return 0;
  }

  /// 切换页序
  void set(int index) {
    state = index;
  }
}
