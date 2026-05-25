import 'dart:convert';

import 'package:clipshare/app/data/models/rule/rule_apply_result.dart';

///规则执行结果
class RuleExecResult {
  final bool success;
  final String? errorMsg;
  final RuleApplyResult? result;
  List<String>? outputs;

  RuleExecResult._private({
    required this.success,
    this.errorMsg,
    this.result,
    this.outputs,
  });

  factory RuleExecResult.success(
    RuleApplyResult result, {
    List<String>? testOutPuts,
  }) {
    return RuleExecResult._private(
      success: true,
      result: result,
      outputs: testOutPuts,
    );
  }

  factory RuleExecResult.ignore() {
    return RuleExecResult._private(
      success: false,
      result: const RuleApplyResult(
        tags: {},
        isSyncDisabled: false,
        isFinalRule: false,
        content: '',
      ),
    );
  }

  factory RuleExecResult.error(String error) {
    return RuleExecResult._private(success: false, errorMsg: error);
  }

  Map<String, dynamic> toJson() {
    return {
      "success": success,
      "errorMsg": errorMsg,
      "result": result?.toJson(),
    };
  }

  @override
  String toString() {
    String formattedJson = const JsonEncoder.withIndent('\t').convert(toJson());
    return formattedJson;
  }
}
