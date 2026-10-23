/// 验证页路由参数
class AuthenticationRouteArgs {
  /// 是否为锁定模式（禁止直接返回，用于启动锁与超时/亮屏重验）
  final bool lock;

  /// 系统生物识别验证的展示文案
  final String? localizedReason;

  const AuthenticationRouteArgs({
    required this.lock,
    this.localizedReason,
  });
}
