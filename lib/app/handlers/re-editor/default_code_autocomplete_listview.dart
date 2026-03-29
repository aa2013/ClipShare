import 'dart:math';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/re-editor/case_insensitive_keyword_prompt.dart';
import 'package:clipshare/app/data/models/re-editor/function_prompt.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:clipshare/app/utils/extensions/re_editor_extension.dart';
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

import 'auto_scroll_listview.dart';

class DefaultCodeAutocompleteListView extends StatefulWidget implements PreferredSizeWidget {
  static const double kItemHeight = 26;
  static const TextStyle kCommentStyle = TextStyle(color: Colors.brown, fontSize: 12);

  final ValueNotifier<CodeAutocompleteEditingValue> notifier;
  final ValueChanged<CodeAutocompleteResult> onSelected;

  const DefaultCodeAutocompleteListView({
    super.key,
    required this.notifier,
    required this.onSelected,
  });

  @override
  Size get preferredSize => Size(
    250,
    // 2 is border size
    min(kItemHeight * notifier.value.prompts.length, 150) + 2,
  );

  @override
  State<StatefulWidget> createState() => _DefaultCodeAutocompleteListViewState();
}

class _DefaultCodeAutocompleteListViewState extends State<DefaultCodeAutocompleteListView> {
  final controller = ScrollController();

  @override
  void initState() {
    widget.notifier.addListener(_onValueChanged);
    super.initState();
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onValueChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scrollerView = AutoScrollListView(
      controller: controller,
      initialIndex: widget.notifier.value.index,
      scrollDirection: Axis.vertical,
      itemCount: widget.notifier.value.prompts.length,
      itemBuilder: (context, index) {
        final CodePrompt prompt = widget.notifier.value.prompts[index];
        final BorderRadius radius = BorderRadius.only(
          topLeft: index == 0 ? const Radius.circular(5) : Radius.zero,
          topRight: index == 0 ? const Radius.circular(5) : Radius.zero,
          bottomLeft: index == widget.notifier.value.prompts.length - 1 ? const Radius.circular(5) : Radius.zero,
          bottomRight: index == widget.notifier.value.prompts.length - 1 ? const Radius.circular(5) : Radius.zero,
        );
        TranslationKey? desc;
        if (prompt is CaseInsensitiveKeywordPrompt) {
          desc = prompt.desc;
        }
        return InkWell(
          borderRadius: radius,
          onTap: () {
            widget.onSelected(widget.notifier.value.copyWith(index: index).autocomplete);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 5, right: 5),
            alignment: Alignment.centerLeft,
            constraints: BoxConstraints(
              minHeight: widget.notifier.value.prompts.length == 1 ? 50 : DefaultCodeAutocompleteListView.kItemHeight,
              maxHeight: double.infinity,
            ),
            decoration: BoxDecoration(
              color: index == widget.notifier.value.index ? const Color(0xffd4e2ff) : null,
              borderRadius: radius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: prompt.createSpan(context, widget.notifier.value.input),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (desc != null)
                  Padding(
                    padding: 2.insetV,
                    child: RichText(
                      text: TextSpan(
                        text: desc.tr,
                        style: DefaultCodeAutocompleteListView.kCommentStyle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    return Container(
      constraints: BoxConstraints.loose(widget.preferredSize),
      decoration: BoxDecoration(
        color: const Color(0xfff7f8fa),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: scrollerView,
    );
  }

  void _onValueChanged() {
    setState(() {});
  }
}
