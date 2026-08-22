class SecuritySettings {
  ///使用安全认证
  final bool useAuthentication;

  ///app密码
  final String? appPassword;

  ///app密码重新验证时长
  final int appRevalidateDuration;

  ///设备连接DH参数加密密钥
  final String dhEncryptKey;

  const SecuritySettings({
    this.useAuthentication = false,
    this.appPassword,
    this.appRevalidateDuration = 0,
    this.dhEncryptKey = '',
  });
}
