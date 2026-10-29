import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_page_index_provider.g.dart';

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
