import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:clipshare_clipboard_listener/clipboard_manager.dart';
import 'package:clipshare_clipboard_listener/enums.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jieba_flutter/analysis/jieba_segmenter.dart';
import 'package:jieba_flutter/analysis/seg_token.dart';

class SegmentTestView extends StatefulWidget {
  final String text;
  final void Function() onClose;

  const SegmentTestView({
    super.key,
    required this.text,
    required this.onClose,
  });

  @override
  State<StatefulWidget> createState() => _SegmentTestViewState();
}

class _SegmentTestViewState extends State<SegmentTestView> {
  final List<SegToken> tokens = [];
  final Set<int> selectedTokens = {};

  @override
  void initState() {
    super.initState();
    var seg = JiebaSegmenter();
    tokens.addAll(seg.process(widget.text, SegMode.SEARCH));
  }

  void onClose() {
    widget.onClose();
    setState(() {
      tokens.clear();
      selectedTokens.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(tokens.length, (index) {
                    final token = tokens[index];
                    return RoundedChip(
                      label: Text(token.word),
                      showCheckmark: false,
                      selected: selectedTokens.contains(index),
                      onSelected: (selected) {
                        if (selected) {
                          selectedTokens.add(index);
                        } else {
                          selectedTokens.remove(index);
                        }
                        setState(() {});
                      },
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Tooltip(
                message: TranslationKey.copyContent.tr,
                child: IconButton(
                  onPressed: () {
                    final indexList = selectedTokens.toList()..sort((a, b) => a - b);
                    final content = indexList.map((i) => tokens[i].word).join("");
                    clipboardManager.copy(ClipboardContentType.text, content);
                    Global.showSnackBarSuc(context: context, text: TranslationKey.copySuccess.tr);
                    onClose();
                  },
                  icon: const Icon(Icons.copy, color: Colors.blueGrey),
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: TranslationKey.close.tr,
                child: IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.blueGrey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
