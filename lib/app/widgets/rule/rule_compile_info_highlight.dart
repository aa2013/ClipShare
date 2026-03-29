import 'package:flutter/material.dart';

class RuleCompileHighLight extends StatelessWidget {
  final String compileInfo;
  final double fontSize;

  const RuleCompileHighLight({
    super.key,
    required this.compileInfo,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      color: const Color(0xff383a42),
      fontSize: fontSize,
      height: 1.4,
      fontFamily: 'monospace',
    );
    const emptyLine = TextSpan(text: "\n");
    final lines = compileInfo.split("\n");
    return SizedBox(
      width: double.infinity,
      child: SelectableText.rich(
        TextSpan(
          style: baseStyle,
          children: [
            TextSpan(
              text: lines[0],
              style: TextStyle(color: lines.length == 1 ? Colors.green : const Color(0xffE06C75)),
            ),
            emptyLine,
            for (var i = 1; i < lines.length; i++)
              TextSpan(
                text: lines[i],
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
