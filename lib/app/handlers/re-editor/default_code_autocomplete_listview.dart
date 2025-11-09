import 'dart:math';

import 'package:clipshare/app/utils/extensions/re_editor_extension.dart';
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

import 'auto_scroll_listview.dart';

class DefaultCodeAutocompleteListView extends StatefulWidget implements PreferredSizeWidget {
  static const double kItemHeight = 26;

  final ValueNotifier<CodeAutocompleteEditingValue> notifier;
  final ValueChanged<CodeAutocompleteResult> onSelected;

  const DefaultCodeAutocompleteListView({
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
      controller: ScrollController(),
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
        return InkWell(
          borderRadius: radius,
          onTap: () {
            widget.onSelected(widget.notifier.value.copyWith(index: index).autocomplete);
          },
          child: Container(
            width: double.infinity,
            height: DefaultCodeAutocompleteListView.kItemHeight,
            padding: const EdgeInsets.only(left: 5, right: 5),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(color: index == widget.notifier.value.index ? Color(0xffd4e2ff) : null, borderRadius: radius),
            child: RichText(
              text: prompt.createSpan(context, widget.notifier.value.input),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        );
      },
    );

    return Container(
      constraints: BoxConstraints.loose(widget.preferredSize),
      decoration: BoxDecoration(
        color: Color(0xfff7f8fa),
        borderRadius: BorderRadius.circular(10),
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
