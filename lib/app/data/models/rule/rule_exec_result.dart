///规则执行结果
class RuleExecResult {
  final bool success;
  final String? errorMsg;

  const RuleExecResult._private({
    required this.success,
    this.errorMsg,
  });

  factory RuleExecResult.success() {
    return const RuleExecResult._private(success: true);
  }

  factory RuleExecResult.error() {
    return const RuleExecResult._private(success: false);
  }
}
