import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/rule/rule_exec_result.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:flutter/material.dart';

class RuleResultHighLight extends StatelessWidget {
  final RuleExecResult result;
  final double fontSize;

  const RuleResultHighLight({
    super.key,
    required this.result,
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

    final r = result.result;
    return SizedBox(
      width: double.infinity,
      child: SelectableText.rich(
        TextSpan(
          style: baseStyle,
          children: [
            TextSpan(
              text: '${TranslationKey.result.tr}: ',
              style: const TextStyle(color: Color(0xffA0A1A7)),
            ),
            TextSpan(
              text: (result.success ? TranslationKey.success.tr : TranslationKey.failed.tr).toUpperCase(),
              style: TextStyle(
                color: result.success ? const Color(0xff50A14F) : const Color(0xffE06C75),
                fontWeight: FontWeight.bold,
              ),
            ),
            emptyLine,
            if (!result.success) ...[
              TextSpan(
                text: '${TranslationKey.error.tr.upperFirst}: ',
                style: const TextStyle(color: Color(0xffE06C75)),
              ),
              TextSpan(
                text: result.errorMsg ?? '',
                style: const TextStyle(color: Color(0xffE06C75)),
              ),
              emptyLine,
            ],
            if (result.success) ...[
              if (r?.title != null) ...[
                TextSpan(
                  text: '${TranslationKey.title.tr.upperFirst}: ',
                  style: const TextStyle(color: Color(0xffC678DD)),
                ),
                TextSpan(
                  text: r?.title ?? '',
                ),
                emptyLine,
              ],
              TextSpan(
                text: '${TranslationKey.content.tr.upperFirst}: ',
                style: const TextStyle(color: Color(0xff61AFEF)),
              ),
              TextSpan(
                text: r?.content ?? '',
              ),
              emptyLine,
              TextSpan(
                text: '${TranslationKey.extracted.tr.upperFirst}: ',
                style: const TextStyle(color: Color(0xffE5C07B)),
              ),
              TextSpan(
                text: r?.extractedContent ?? '',
              ),
              emptyLine,
              TextSpan(
                text: '${TranslationKey.tags.tr.upperFirst}: ',
                style: const TextStyle(color: Color(0xff56B6C2)),
              ),
              if (r != null && r.tags.isNotEmpty)
                ...r.tags.map(
                  (tag) => TextSpan(
                    text: '[$tag] ',
                    style: const TextStyle(color: Color(0xff56B6C2)),
                  ),
                )
              else
                const TextSpan(text: ''),
              emptyLine,
              TextSpan(
                text: '${TranslationKey.flags.tr.upperFirst}: ',
                style: const TextStyle(color: Color(0xffA0A1A7)),
              ),
              if (r?.isFinalRule == true)
                TextSpan(
                  text: '[${TranslationKey.finalRule.tr.toUpperCase()}] ',
                  style: const TextStyle(color: Color(0xff98C379)),
                ),
              if (r?.isDropped == true)
                TextSpan(
                  text: '[${TranslationKey.dropped.tr.toUpperCase()}] ',
                  style: const TextStyle(color: Color(0xffE06C75)),
                ),
              if (r?.isSyncDisabled == true)
                TextSpan(
                  text: '[${TranslationKey.syncDisabled.tr.replaceAll(' ', '_').toUpperCase()}] ',
                  style: const TextStyle(color: Color(0xffD19A66)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
