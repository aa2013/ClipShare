import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/rule.dart';
import 'package:flutter/material.dart';

class RuleItem extends StatefulWidget {
  final Rule rule;
  final Widget action;
  final void Function(bool selected) onSelectionChange;
  final BorderRadius borderRadius;
  late void Function()? onLongPress;
  late void Function()? onTap;
  final EdgeInsetsGeometry padding;
  bool selected;
  bool selectionMode = false;
  Color? backgroundColor;

  RuleItem({
    super.key,
    required this.rule,
    required this.action,
    this.onLongPress,
    this.onTap,
    this.selectionMode = false,
    this.selected = false,
    this.backgroundColor,
    this.borderRadius = BorderRadius.zero,
    this.padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    required this.onSelectionChange,
  });

  @override
  State<RuleItem> createState() => _RuleItemState();
}

class _RuleItemState extends State<RuleItem> {
  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Material(
        color: widget.backgroundColor ??
            currentTheme.cardTheme.color ??
            currentTheme.colorScheme.surface,
        child: InkWell(
          onTap: () {
            widget.onTap?.call();
          },
          onLongPress: widget.onLongPress,
          mouseCursor: SystemMouseCursors.basic,
          child: Column(
            children: [
              Padding(
                padding: widget.padding,
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DefaultTextStyle(
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 17,
                                ),
                                child: Text("${TranslationKey.name_.tr}: ${widget.rule.name}"),
                              ),
                            ),
                            DefaultTextStyle(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                color: Colors.grey,
                              ),
                              child: Text("${TranslationKey.ruleContent.tr}: ${widget.rule.rule}",maxLines: 3,),
                            ),
                          ],
                        ),
                      ),
                      IntrinsicWidth(
                        child: Visibility(
                          visible: widget.selectionMode,
                          replacement: widget.action,
                          child: Checkbox(
                            value: widget.selected,
                            onChanged: (v) => widget.onSelectionChange.call(v ?? false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
