import 'package:flutter/material.dart';

class LogLineHighLight extends StatelessWidget {
  final String log;
  final double fontSize;

  const LogLineHighLight({
    super.key,
    required this.log,
    this.fontSize = 12,
  });

  static const _logSepColor = Color(0xffABB2BF);
  static const _logTimeColor = Color(0xff50a14f);
  static const _logTagColor = Color(0xffC678DD);

  @override
  Widget build(BuildContext context) {
    // 日志正则（严格匹配）
    final regex = RegExp(
      r'^\[(debug|info|warn|error)\] \| (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \| \[([^\]]+)\] \| (.*)$',
    );

    final match = regex.firstMatch(log);

    // ❌ 不符合格式 → 普通文本
    if (match == null) {
      return Text(
        log,
        style: const TextStyle(color: Color(0xff383a42)),
      );
    }

    final level = match.group(1)!;
    final time = match.group(2)!;
    final tag = match.group(3)!;
    final message = match.group(4)!;

    // 🎨 颜色（跟你前面主题统一）
    Color levelColor;
    switch (level) {
      case 'debug':
        levelColor = const Color(0xff56B6C2);
        break;
      case 'info':
        levelColor = const Color(0xff61AFEF);
        break;
      case 'warn':
        levelColor = const Color(0xffE5C07B);
        break;
      case 'error':
        levelColor = const Color(0xffE06C75);
        break;
      default:
        levelColor = const Color(0xff383a42);
    }
    return SelectableText.rich(
      TextSpan(
        style: TextStyle(
          color: const Color(0xff383a42),
          fontSize: fontSize,
        ),
        children: [
          // 时间
          TextSpan(
            text: time.split(" ")[1],
            style: const TextStyle(color: _logTimeColor),
          ),

          const TextSpan(
            text: ' | ',
            style: TextStyle(color: _logSepColor),
          ),

          // [level]
          TextSpan(
            text: '[$level]',
            style: TextStyle(color: levelColor),
          ),

          const TextSpan(
            text: ' | ',
            style: TextStyle(color: _logSepColor),
          ),

          // [tag]
          TextSpan(
            text: '[$tag]',
            style: const TextStyle(color: _logTagColor),
          ),

          const TextSpan(
            text: ' | ',
            style: TextStyle(color: _logSepColor),
          ),

          // 内容
          TextSpan(
            text: message,
          ),
        ],
      ),
    );
  }
}
