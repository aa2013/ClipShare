/// DH 加密密钥输入校验
class DhKeyValidator {
  DhKeyValidator._();

  /// 密钥最小长度（去除空白转义序列后计算）
  static const minLength = 8;

  /// 输入内容中的空白转义序列，校验长度前移除
  static const whitespaceEscape = '\\s+';

  /// 校验输入的密钥是否合法。
  ///
  /// [hasCurrentKey] 当前是否已配置密钥；已配置时允许输入为空（表示清空）。
  static bool verify(String input, {required bool hasCurrentKey}) {
    if (input.isEmpty) {
      return hasCurrentKey;
    }
    return input.replaceAll(whitespaceEscape, '').length >= minLength;
  }
}
