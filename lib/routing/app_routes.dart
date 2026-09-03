/// 应用路由统一定义，每个枚举值承载 go_router 的 path 与 name，
/// 避免页面跳转时散落魔法字符串。
enum AppRoutes {
  splash('/splash', 'splash'),
  home('/home', 'home'),
  imagePreview('/imagePreview', 'imagePreview'),
  segmentWords('/segmentWords', 'segmentWords');

  const AppRoutes(this.path, this.name);

  /// 路由完整路径（含前导斜杠），用于 GoRoute.path 注册。
  final String path;

  /// 路由名称，用于 pushNamed / replaceNamed 等命名跳转。
  final String name;
}
